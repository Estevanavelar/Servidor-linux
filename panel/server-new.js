#!/usr/bin/env node

/**
 * Professional Server Control Panel
 * Production-ready hosting management system
 */

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const fs = require('fs-extra');
const { exec, spawn } = require('child_process');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const cron = require('node-cron');
const moment = require('moment');
const { v4: uuidv4 } = require('uuid');
const si = require('systeminformation');
const nodemailer = require('nodemailer');

require('dotenv').config();

// Initialize Express app and server
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: process.env.PANEL_URL || "*",
        methods: ["GET", "POST"]
    }
});

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const SECRET_KEY = process.env.SECRET_KEY || require('crypto').randomBytes(64).toString('hex');

// Logging Configuration
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    transports: [
        new DailyRotateFile({
            filename: 'logs/application-%DATE%.log',
            datePattern: 'YYYY-MM-DD',
            maxSize: process.env.LOG_MAX_SIZE || '10m',
            maxFiles: process.env.LOG_MAX_FILES || '5d'
        }),
        new DailyRotateFile({
            filename: 'logs/error-%DATE%.log',
            datePattern: 'YYYY-MM-DD',
            level: 'error',
            maxSize: '5m',
            maxFiles: '10d'
        })
    ]
});

if (NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple()
    }));
}

// Email Configuration
let emailTransporter = null;
if (process.env.SMTP_HOST) {
    emailTransporter = nodemailer.createTransporter({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT || 587,
        secure: process.env.SMTP_PORT == 465,
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });
}

// Security Middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://cdn.tailwindcss.com", "https://cdnjs.cloudflare.com"],
            fontSrc: ["'self'", "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"],
            scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "ws:", "wss:"]
        }
    }
}));

app.use(compression());

// Rate Limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
    message: { error: 'Too many requests, please try again later.' }
});

const speedLimiter = slowDown({
    windowMs: 15 * 60 * 1000,
    delayAfter: 50,
    delayMs: 500,
    maxDelayMs: 20000
});

app.use('/api/', limiter);
app.use('/api/', speedLimiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// System Status Storage
let systemStatus = {
    cpu: [],
    memory: [],
    disk: {},
    services: {},
    lastUpdate: new Date(),
    uptime: 0
};

// ====================
// UTILITY FUNCTIONS
// ====================

const execAsync = (command) => {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                logger.error('Command execution failed', { command, error: error.message, stderr });
                reject({ error: error.message, stderr });
            } else {
                resolve({ stdout, stderr });
            }
        });
    });
};

const sendNotification = async (type, message, details = {}) => {
    const notification = {
        id: uuidv4(),
        type,
        message,
        details,
        timestamp: new Date().toISOString()
    };
    
    // Send via WebSocket
    io.emit('notification', notification);
    
    // Send email if configured and it's an error
    if (emailTransporter && type === 'error' && process.env.ALERT_EMAIL) {
        try {
            await emailTransporter.sendMail({
                from: process.env.SMTP_FROM,
                to: process.env.ALERT_EMAIL,
                subject: `Server Alert: ${message}`,
                html: `
                    <h3>Server Alert</h3>
                    <p><strong>Type:</strong> ${type}</p>
                    <p><strong>Message:</strong> ${message}</p>
                    <p><strong>Time:</strong> ${notification.timestamp}</p>
                    <p><strong>Details:</strong> ${JSON.stringify(details, null, 2)}</p>
                `
            });
        } catch (error) {
            logger.error('Failed to send email notification', error);
        }
    }
    
    logger.info('Notification sent', notification);
};

// ====================
// AUTHENTICATION MIDDLEWARE
// ====================

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) {
            logger.warn('Invalid token attempt', { token: token.substr(0, 20), ip: req.ip });
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
};

// ====================
// SYSTEM MONITORING
// ====================

const updateSystemStats = async () => {
    try {
        const [cpu, memory, diskLayout, services] = await Promise.all([
            si.currentLoad(),
            si.mem(),
            si.diskLayout(),
            checkAllServices()
        ]);

        // Update CPU history
        systemStatus.cpu.push({
            usage: cpu.currentload,
            timestamp: new Date()
        });
        if (systemStatus.cpu.length > 288) { // Keep 24 hours of data (5min intervals)
            systemStatus.cpu.shift();
        }

        // Update Memory history
        systemStatus.memory.push({
            total: memory.total,
            used: memory.used,
            usage: (memory.used / memory.total) * 100,
            timestamp: new Date()
        });
        if (systemStatus.memory.length > 288) {
            systemStatus.memory.shift();
        }

        // Update disk info
        systemStatus.disk = diskLayout[0] || {};
        
        // Update services
        systemStatus.services = services;
        systemStatus.lastUpdate = new Date();

        // Broadcast to connected clients
        io.emit('system_update', {
            type: 'stats',
            data: {
                system: {
                    cpu: cpu.currentload,
                    memory: (memory.used / memory.total) * 100,
                    diskUsage: 75, // TODO: Calculate real disk usage
                },
                sites: await getSitesStats(),
                ssl: await getSSLStats(),
                databases: await getDatabaseStats()
            }
        });

        // Check for alerts
        if (cpu.currentload > 90) {
            sendNotification('error', 'High CPU usage detected', { usage: cpu.currentload });
        }
        
        if ((memory.used / memory.total) * 100 > 90) {
            sendNotification('error', 'High memory usage detected', { usage: (memory.used / memory.total) * 100 });
        }

    } catch (error) {
        logger.error('Failed to update system stats', error);
    }
};

const checkAllServices = async () => {
    const services = ['nginx', 'mysql', 'postgresql', 'redis', 'php8.1-fpm'];
    const results = {};
    
    for (const service of services) {
        try {
            await execAsync(`systemctl is-active ${service}`);
            results[service] = { name: service, running: true };
        } catch (error) {
            results[service] = { name: service, running: false };
        }
    }
    
    return results;
};

// ====================
// ROUTES
// ====================

// Authentication Routes
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        const adminUser = process.env.ADMIN_USER || 'admin';
        const adminPasswordHash = process.env.ADMIN_PASSWORD_HASH;
        
        if (username === adminUser && adminPasswordHash) {
            const isValid = await bcrypt.compare(password, adminPasswordHash);
            if (isValid) {
                const token = jwt.sign(
                    { username, role: 'admin' },
                    SECRET_KEY,
                    { expiresIn: '24h' }
                );
                
                logger.info('Successful login', { username, ip: req.ip });
                
                res.json({
                    success: true,
                    token,
                    message: 'Login successful'
                });
            } else {
                logger.warn('Invalid login attempt', { username, ip: req.ip });
                res.status(401).json({ error: 'Invalid credentials' });
            }
        } else {
            logger.warn('Login attempt with invalid user', { username, ip: req.ip });
            res.status(401).json({ error: 'Invalid credentials' });
        }
    } catch (error) {
        logger.error('Login error', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// System Stats Route
app.get('/api/system/stats', authenticateToken, async (req, res) => {
    try {
        const stats = {
            system: {
                cpu: systemStatus.cpu.slice(-1)[0]?.usage || 0,
                memory: systemStatus.memory.slice(-1)[0]?.usage || 0,
                diskUsage: 75, // TODO: Calculate real disk usage
                uptime: process.uptime()
            },
            sites: await getSitesStats(),
            ssl: await getSSLStats(),
            databases: await getDatabaseStats(),
            services: systemStatus.services
        };
        
        res.json({ success: true, data: stats });
    } catch (error) {
        logger.error('Failed to get system stats', error);
        res.status(500).json({ error: 'Failed to get system stats' });
    }
});

// Hosting Management Routes
app.get('/api/hosting/sites', authenticateToken, async (req, res) => {
    try {
        const sites = await getHostingSites();
        res.json({ success: true, data: sites });
    } catch (error) {
        logger.error('Failed to get hosting sites', error);
        res.status(500).json({ error: 'Failed to get hosting sites' });
    }
});

app.post('/api/hosting/create', authenticateToken, async (req, res) => {
    try {
        const { domain, directory, php, ssl } = req.body;
        
        if (!domain) {
            return res.status(400).json({ error: 'Domain is required' });
        }
        
        const result = await createHostingSite({
            domain,
            directory: directory || `/var/www/${domain.replace(/[^a-zA-Z0-9.-]/g, '')}`,
            php: !!php,
            ssl: !!ssl
        });
        
        if (result.success) {
            logger.info('Hosting site created', { domain, php, ssl });
            sendNotification('success', `Site ${domain} created successfully`);
            res.json(result);
        } else {
            res.status(500).json(result);
        }
    } catch (error) {
        logger.error('Failed to create hosting site', error);
        res.status(500).json({ error: 'Failed to create hosting site' });
    }
});

// SSL Management Routes
app.post('/api/ssl/obtain', authenticateToken, async (req, res) => {
    try {
        const { domain, email } = req.body;
        
        if (!domain || !email) {
            return res.status(400).json({ error: 'Domain and email are required' });
        }
        
        const result = await obtainSSLCertificate(domain, email);
        res.json(result);
    } catch (error) {
        logger.error('Failed to obtain SSL certificate', error);
        res.status(500).json({ error: 'Failed to obtain SSL certificate' });
    }
});

// ====================
// HELPER FUNCTIONS
// ====================

const getSitesStats = async () => {
    try {
        const sites = await getHostingSites();
        return {
            active: sites.filter(s => s.active).length,
            total: sites.length
        };
    } catch (error) {
        return { active: 0, total: 0 };
    }
};

const getSSLStats = async () => {
    try {
        const result = await execAsync('certbot certificates 2>/dev/null | grep "Certificate Name:" | wc -l');
        return {
            active: parseInt(result.stdout.trim()) || 0
        };
    } catch (error) {
        return { active: 0 };
    }
};

const getDatabaseStats = async () => {
    try {
        // Count MySQL databases
        const mysqlResult = await execAsync('mysql -e "SHOW DATABASES;" 2>/dev/null | wc -l');
        const mysqlCount = Math.max(0, parseInt(mysqlResult.stdout.trim()) - 4); // Subtract system databases
        
        return { total: mysqlCount };
    } catch (error) {
        return { total: 0 };
    }
};

const getHostingSites = async () => {
    try {
        const sitesDir = '/etc/nginx/sites-available';
        const enabledDir = '/etc/nginx/sites-enabled';
        
        const available = await fs.readdir(sitesDir);
        const enabled = await fs.readdir(enabledDir);
        
        const sites = [];
        
        for (const site of available) {
            if (site === 'default') continue;
            
            try {
                const configPath = path.join(sitesDir, site);
                const config = await fs.readFile(configPath, 'utf8');
                const serverNameMatch = config.match(/server_name\\s+([^;]+);/);
                const domain = serverNameMatch ? serverNameMatch[1].trim() : site;
                
                sites.push({
                    id: site,
                    domain,
                    active: enabled.includes(site),
                    ssl: config.includes('ssl_certificate'),
                    configPath,
                    lastAccess: null // TODO: Get from access logs
                });
            } catch (error) {
                logger.error(`Failed to read config for site ${site}`, error);
            }
        }
        
        return sites;
    } catch (error) {
        logger.error('Failed to get hosting sites', error);
        return [];
    }
};

const createHostingSite = async ({ domain, directory, php, ssl }) => {
    try {
        const siteName = domain.replace(/[^a-zA-Z0-9.-]/g, '');
        
        // Create directory
        await fs.ensureDir(directory);
        await execAsync(`chown -R www-data:www-data ${directory}`);
        await execAsync(`chmod -R 755 ${directory}`);
        
        // Create Nginx configuration
        let config = `server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain};
    root ${directory};
    index index.html index.htm${php ? ' index.php' : ''};
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    location / {
        try_files $uri $uri/ =404;
    }`;

        if (php) {
            config += `
    
    location ~ \\.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }`;
        }

        config += `
    
    location ~ /\\.ht {
        deny all;
    }
    
    # Additional security
    location ~ /\\.(git|svn) {
        deny all;
    }
}`;

        // Save configuration
        const configPath = `/etc/nginx/sites-available/${siteName}`;
        await fs.writeFile(configPath, config);
        
        // Enable site
        await execAsync(`ln -sf ${configPath} /etc/nginx/sites-enabled/`);
        
        // Test and reload Nginx
        await execAsync('nginx -t');
        await execAsync('systemctl reload nginx');
        
        // Create index file
        const indexContent = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to ${domain}!</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0; padding: 40px; background: #f8f9fa; text-align: center;
        }
        .container { 
            max-width: 600px; margin: 0 auto; background: white; 
            padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #2c3e50; margin-bottom: 20px; }
        .badge { 
            display: inline-block; padding: 4px 8px; background: #27ae60; 
            color: white; border-radius: 4px; font-size: 12px; margin: 5px;
        }
        code { background: #f8f9fa; padding: 2px 6px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Site ${domain} Online!</h1>
        <p>Seu site foi configurado com sucesso no servidor profissional.</p>
        ${php ? '<span class="badge">PHP Enabled</span>' : ''}
        ${ssl ? '<span class="badge">SSL Ready</span>' : ''}
        <p><strong>Diretório:</strong> <code>${directory}</code></p>
        <p>Faça upload dos seus arquivos para começar!</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #dee2e6;">
        <p><small>Powered by Professional Server Panel</small></p>
    </div>
</body>
</html>`;
        
        await fs.writeFile(path.join(directory, 'index.html'), indexContent);
        
        // Obtain SSL if requested
        if (ssl && process.env.CERTBOT_EMAIL) {
            try {
                await obtainSSLCertificate(domain, process.env.CERTBOT_EMAIL);
            } catch (error) {
                logger.warn('SSL certificate creation failed', { domain, error: error.message });
            }
        }
        
        return {
            success: true,
            message: `Site ${domain} created successfully`,
            data: { siteName, domain, directory, configPath, php, ssl }
        };
        
    } catch (error) {
        logger.error('Failed to create hosting site', error);
        return { success: false, error: error.message };
    }
};

const obtainSSLCertificate = async (domain, email) => {
    try {
        const result = await execAsync(
            `certbot --nginx -d ${domain} --email ${email} --agree-tos --non-interactive --redirect`
        );
        
        logger.info('SSL certificate obtained', { domain });
        sendNotification('success', `SSL certificate obtained for ${domain}`);
        
        return {
            success: true,
            message: `SSL certificate obtained for ${domain}`,
            data: result.stdout
        };
    } catch (error) {
        logger.error('Failed to obtain SSL certificate', { domain, error });
        return {
            success: false,
            error: `Failed to obtain SSL: ${error.message}`
        };
    }
};

// ====================
// WEBSOCKET HANDLING
// ====================

io.on('connection', (socket) => {
    logger.info('WebSocket client connected', { socketId: socket.id });
    
    socket.on('disconnect', () => {
        logger.info('WebSocket client disconnected', { socketId: socket.id });
    });
    
    // Send initial system data
    socket.emit('system_update', {
        type: 'initial',
        data: systemStatus
    });
});

// ====================
// CRON JOBS
// ====================

// System monitoring every 5 minutes
cron.schedule('*/5 * * * *', () => {
    updateSystemStats();
});

// Daily backup at 2 AM
cron.schedule('0 2 * * *', async () => {
    try {
        const timestamp = moment().format('YYYY-MM-DD');
        const backupDir = process.env.BACKUP_LOCATION || '/var/backups/server-panel';
        
        await fs.ensureDir(backupDir);
        
        // Backup websites
        await execAsync(`tar -czf ${backupDir}/sites-${timestamp}.tar.gz /var/www`);
        
        // Backup Nginx configs
        await execAsync(`tar -czf ${backupDir}/nginx-${timestamp}.tar.gz /etc/nginx`);
        
        // Backup databases
        await execAsync(`mysqldump --all-databases > ${backupDir}/mysql-${timestamp}.sql`);
        
        logger.info('Daily backup completed', { timestamp });
        sendNotification('success', 'Daily backup completed successfully');
        
        // Cleanup old backups
        const retentionDays = process.env.BACKUP_RETENTION_DAYS || 30;
        await execAsync(`find ${backupDir} -type f -mtime +${retentionDays} -delete`);
        
    } catch (error) {
        logger.error('Daily backup failed', error);
        sendNotification('error', 'Daily backup failed', error);
    }
});

// SSL renewal check every day at 3 AM
cron.schedule('0 3 * * *', async () => {
    try {
        await execAsync('certbot renew --quiet --no-self-upgrade');
        logger.info('SSL renewal check completed');
    } catch (error) {
        logger.error('SSL renewal check failed', error);
        sendNotification('error', 'SSL renewal failed', error);
    }
});

// ====================
// ROUTES
// ====================

// Serve the main application
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index-new.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        version: process.env.npm_package_version || '2.0.0'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((error, req, res, next) => {
    logger.error('Unhandled error', { error: error.message, stack: error.stack, url: req.url });
    res.status(500).json({ error: 'Internal server error' });
});

// ====================
// START SERVER
// ====================

server.listen(PORT, () => {
    logger.info('Professional Server Panel started', {
        port: PORT,
        environment: NODE_ENV,
        url: process.env.PANEL_URL || `http://localhost:${PORT}`
    });
    
    console.log(`\\n🚀 Professional Server Panel`);
    console.log(`📊 Port: ${PORT}`);
    console.log(`🌍 Environment: ${NODE_ENV}`);
    console.log(`🔗 URL: ${process.env.PANEL_URL || `http://localhost:${PORT}`}`);
    console.log(`👤 Admin: ${process.env.ADMIN_USER || 'admin'}`);
    console.log(`📝 Logs: logs/application-*.log\\n`);
    
    // Initial system stats update
    updateSystemStats();
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    server.close(() => {
        logger.info('Server closed');
        process.exit(0);
    });
});

module.exports = { app, server };
