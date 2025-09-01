#!/usr/bin/env node

const express = require('express');
const path = require('path');
const fs = require('fs-extra');
const { exec } = require('child_process');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const WebSocket = require('ws');
const cron = require('node-cron');

const app = express();
const PORT = process.env.PORT || 8080;
const SECRET_KEY = process.env.SECRET_KEY || 'sua-chave-secreta-aqui';

// Middleware de segurança
app.use(helmet({
    contentSecurityPolicy: false // Permitir scripts inline para o painel
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100 // máximo 100 requests por IP
});
app.use(limiter);

// CORS e body parser
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Servir arquivos estáticos
app.use(express.static(path.join(__dirname, 'public')));

// Middleware de autenticação
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token de acesso necessário' });
    }

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Token inválido' });
        }
        req.user = user;
        next();
    });
};

// Função para executar comandos shell
const execCommand = (command) => {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                reject({ error: error.message, stderr });
            } else {
                resolve({ stdout, stderr });
            }
        });
    });
};

// ====================
// ROTAS DE AUTENTICAÇÃO
// ====================

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        // Por segurança, verificar credenciais do sistema
        // Em produção, usar banco de dados adequado
        const defaultUser = 'admin';
        const defaultPass = 'admin123'; // ALTERAR EM PRODUÇÃO!
        
        if (username === defaultUser && password === defaultPass) {
            const token = jwt.sign({ username }, SECRET_KEY, { expiresIn: '24h' });
            res.json({ 
                success: true, 
                token,
                message: 'Login realizado com sucesso'
            });
        } else {
            res.status(401).json({ error: 'Credenciais inválidas' });
        }
    } catch (error) {
        res.status(500).json({ error: 'Erro no servidor' });
    }
});

// ====================
// ROTAS DO SISTEMA
// ====================

// Status do sistema
app.get('/api/system/status', authenticateToken, async (req, res) => {
    try {
        const commands = {
            uptime: 'uptime',
            memory: 'free -m',
            disk: 'df -h',
            cpu: 'cat /proc/loadavg',
            services: 'systemctl is-active nginx mysql postgresql redis php8.1-fpm',
            network: 'ss -tuln'
        };

        const results = {};
        
        for (const [key, command] of Object.entries(commands)) {
            try {
                const result = await execCommand(command);
                results[key] = result.stdout;
            } catch (error) {
                results[key] = `Erro: ${error.error}`;
            }
        }

        res.json({
            success: true,
            data: results,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao obter status do sistema' });
    }
});

// ====================
// ROTAS DO NGINX
// ====================

// Listar sites do Nginx
app.get('/api/nginx/sites', authenticateToken, async (req, res) => {
    try {
        const sitesAvailable = await fs.readdir('/etc/nginx/sites-available').catch(() => []);
        const sitesEnabled = await fs.readdir('/etc/nginx/sites-enabled').catch(() => []);
        
        const sites = [];
        
        for (const site of sitesAvailable) {
            if (site !== 'default') {
                const isEnabled = sitesEnabled.includes(site);
                const configPath = `/etc/nginx/sites-available/${site}`;
                
                try {
                    const config = await fs.readFile(configPath, 'utf8');
                    const serverNameMatch = config.match(/server_name\s+([^;]+);/);
                    const serverName = serverNameMatch ? serverNameMatch[1].trim() : site;
                    
                    sites.push({
                        name: site,
                        serverName,
                        enabled: isEnabled,
                        configPath
                    });
                } catch (error) {
                    sites.push({
                        name: site,
                        serverName: site,
                        enabled: isEnabled,
                        configPath,
                        error: 'Erro ao ler configuração'
                    });
                }
            }
        }
        
        res.json({ success: true, data: sites });
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar sites' });
    }
});

// Criar novo site
app.post('/api/nginx/sites', authenticateToken, async (req, res) => {
    try {
        const { domain, documentRoot, phpEnabled, sslEnabled } = req.body;
        
        if (!domain) {
            return res.status(400).json({ error: 'Domínio é obrigatório' });
        }
        
        const siteName = domain.replace(/[^a-zA-Z0-9.-]/g, '');
        const root = documentRoot || `/var/www/${siteName}`;
        
        // Criar diretório do site
        await fs.ensureDir(root);
        await execCommand(`chown -R www-data:www-data ${root}`);
        
        // Configuração básica do Nginx
        let config = `server {
    listen 80;
    listen [::]:80;
    
    server_name ${domain};
    root ${root};
    index index.html index.htm${phpEnabled ? ' index.php' : ''};
    
    location / {
        try_files $uri $uri/ =404;
    }`;

        if (phpEnabled) {
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
}`;

        // Salvar configuração
        const configPath = `/etc/nginx/sites-available/${siteName}`;
        await fs.writeFile(configPath, config);
        
        // Habilitar site
        await execCommand(`ln -sf ${configPath} /etc/nginx/sites-enabled/`);
        
        // Testar configuração do Nginx
        const testResult = await execCommand('nginx -t');
        
        if (testResult.stderr && !testResult.stderr.includes('successful')) {
            throw new Error('Configuração do Nginx inválida');
        }
        
        // Recarregar Nginx
        await execCommand('systemctl reload nginx');
        
        // Criar arquivo index básico
        const indexContent = `<!DOCTYPE html>
<html>
<head>
    <title>Bem-vindo ao ${domain}!</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
        h1 { color: #2c3e50; }
        .container { max-width: 600px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Site ${domain} configurado!</h1>
        <p>Seu site está funcionando corretamente.</p>
        <p>Faça upload dos seus arquivos para: <code>${root}</code></p>
    </div>
</body>
</html>`;
        
        await fs.writeFile(path.join(root, 'index.html'), indexContent);
        
        res.json({
            success: true,
            message: `Site ${domain} criado com sucesso`,
            data: { siteName, domain, root, configPath }
        });
        
    } catch (error) {
        res.status(500).json({ error: `Erro ao criar site: ${error.message}` });
    }
});

// Habilitar/Desabilitar site
app.patch('/api/nginx/sites/:siteName', authenticateToken, async (req, res) => {
    try {
        const { siteName } = req.params;
        const { action } = req.body; // 'enable' ou 'disable'
        
        const availablePath = `/etc/nginx/sites-available/${siteName}`;
        const enabledPath = `/etc/nginx/sites-enabled/${siteName}`;
        
        if (!await fs.pathExists(availablePath)) {
            return res.status(404).json({ error: 'Site não encontrado' });
        }
        
        if (action === 'enable') {
            await execCommand(`ln -sf ${availablePath} ${enabledPath}`);
        } else if (action === 'disable') {
            await fs.remove(enabledPath);
        } else {
            return res.status(400).json({ error: 'Ação inválida' });
        }
        
        // Testar e recarregar Nginx
        await execCommand('nginx -t');
        await execCommand('systemctl reload nginx');
        
        res.json({
            success: true,
            message: `Site ${siteName} ${action === 'enable' ? 'habilitado' : 'desabilitado'} com sucesso`
        });
        
    } catch (error) {
        res.status(500).json({ error: `Erro ao ${req.body.action} site: ${error.message}` });
    }
});

// ====================
// ROTAS SSL/CERTBOT
// ====================

// Obter certificado SSL
app.post('/api/ssl/obtain', authenticateToken, async (req, res) => {
    try {
        const { domain, email } = req.body;
        
        if (!domain || !email) {
            return res.status(400).json({ error: 'Domínio e email são obrigatórios' });
        }
        
        // Verificar se o domínio resolve para este servidor
        const result = await execCommand(`certbot --nginx -d ${domain} --email ${email} --agree-tos --non-interactive`);
        
        res.json({
            success: true,
            message: `Certificado SSL obtido para ${domain}`,
            data: result.stdout
        });
        
    } catch (error) {
        res.status(500).json({ error: `Erro ao obter SSL: ${error.error || error.message}` });
    }
});

// ====================
// ROTAS DE ARQUIVOS
// ====================

// Listar arquivos
app.get('/api/files', authenticateToken, async (req, res) => {
    try {
        const { path: dirPath = '/var/www' } = req.query;
        
        // Segurança: restringir a certos diretórios
        const allowedPaths = ['/var/www', '/etc/nginx/sites-available', '/etc/nginx/sites-enabled'];
        const isAllowed = allowedPaths.some(allowed => dirPath.startsWith(allowed));
        
        if (!isAllowed) {
            return res.status(403).json({ error: 'Acesso negado a este diretório' });
        }
        
        const items = await fs.readdir(dirPath, { withFileTypes: true });
        const files = [];
        
        for (const item of items) {
            const itemPath = path.join(dirPath, item.name);
            const stats = await fs.stat(itemPath);
            
            files.push({
                name: item.name,
                path: itemPath,
                isDirectory: item.isDirectory(),
                size: stats.size,
                modified: stats.mtime
            });
        }
        
        res.json({ success: true, data: { path: dirPath, files } });
        
    } catch (error) {
        res.status(500).json({ error: 'Erro ao listar arquivos' });
    }
});

// ====================
// WEBSOCKET PARA LOGS EM TEMPO REAL
// ====================

const wss = new WebSocket.Server({ port: 8081 });

wss.on('connection', (ws) => {
    console.log('Cliente WebSocket conectado');
    
    // Enviar logs do Nginx em tempo real
    const tailNginx = exec('tail -f /var/log/nginx/access.log');
    
    tailNginx.stdout.on('data', (data) => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
                type: 'nginx_access',
                data: data.toString()
            }));
        }
    });
    
    ws.on('close', () => {
        console.log('Cliente WebSocket desconectado');
        tailNginx.kill();
    });
});

// ====================
// CRON JOBS
// ====================

// Backup automático dos sites (todo dia às 2h)
cron.schedule('0 2 * * *', async () => {
    try {
        const timestamp = new Date().toISOString().split('T')[0];
        await execCommand(`tar -czf /backups/sites-${timestamp}.tar.gz /var/www`);
        console.log(`Backup automático criado: sites-${timestamp}.tar.gz`);
    } catch (error) {
        console.error('Erro no backup automático:', error);
    }
});

// Renovação automática de SSL (todo dia às 3h)
cron.schedule('0 3 * * *', async () => {
    try {
        await execCommand('certbot renew --quiet');
        console.log('Verificação de renovação SSL executada');
    } catch (error) {
        console.error('Erro na renovação SSL:', error);
    }
});

// ====================
// ROTA PRINCIPAL
// ====================

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint não encontrado' });
});

// Error handler
app.use((error, req, res, next) => {
    console.error('Erro no servidor:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`🚀 Painel de controle rodando em http://localhost:${PORT}`);
    console.log(`📊 WebSocket para logs em tempo real na porta 8081`);
    console.log(`👤 Login padrão: admin / admin123 (ALTERE EM PRODUÇÃO!)`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('Encerrando servidor...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('Encerrando servidor...');
    process.exit(0);
});
