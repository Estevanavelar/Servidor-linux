#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const crypto = require('crypto');
const readline = require('readline');
const bcrypt = require('bcryptjs');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (prompt) => {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
};

async function setup() {
  console.log('\n🚀 Configuração do Painel de Controle Profissional\n');
  
  try {
    // Criar diretórios necessários
    const dirs = [
      'logs',
      'backups',
      'uploads',
      'public/assets',
      'config',
      'ssl-certs'
    ];
    
    for (const dir of dirs) {
      await fs.ensureDir(dir);
      console.log(`✅ Diretório criado: ${dir}`);
    }
    
    // Configurar variáveis de ambiente
    const envFile = '.env';
    let envContent = '';
    
    if (!await fs.pathExists(envFile)) {
      console.log('\n📝 Configurando variáveis de ambiente...\n');
      
      const secretKey = crypto.randomBytes(64).toString('hex');
      const sessionSecret = crypto.randomBytes(32).toString('hex');
      
      const domain = await question('🌐 Domínio do painel (ex: panel.seudominio.com): ');
      const adminEmail = await question('📧 Email do administrador: ');
      const adminUser = await question('👤 Usuário admin: ') || 'admin';
      const adminPassword = await question('🔐 Senha admin: ');
      
      const hashedPassword = await bcrypt.hash(adminPassword, 12);
      
      envContent = `# Painel de Controle - Configurações
NODE_ENV=production
PORT=3000

# Segurança
SECRET_KEY=${secretKey}
SESSION_SECRET=${sessionSecret}

# Domínio
PANEL_DOMAIN=${domain}
PANEL_URL=https://${domain}

# Admin
ADMIN_EMAIL=${adminEmail}
ADMIN_USER=${adminUser}
ADMIN_PASSWORD_HASH=${hashedPassword}

# Banco de dados (opcional)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=server_panel
DB_USER=panel_user
DB_PASS=

# Redis (opcional)
REDIS_URL=redis://localhost:6379

# Email (para notificações)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=${adminEmail}

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_LOCATION=/var/backups/server-panel

# SSL
CERTBOT_EMAIL=${adminEmail}
SSL_AUTO_RENEW=true

# Monitoramento
ENABLE_MONITORING=true
ALERT_EMAIL=${adminEmail}

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# Logging
LOG_LEVEL=info
LOG_MAX_SIZE=10m
LOG_MAX_FILES=5d
`;
      
      await fs.writeFile(envFile, envContent);
      console.log('✅ Arquivo .env criado');
    }
    
    // Configurar Nginx para o painel
    const nginxConfig = `# Painel de Controle - Configuração Nginx
server {
    listen 80;
    server_name ${process.env.PANEL_DOMAIN || 'panel.localhost'};
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${process.env.PANEL_DOMAIN || 'panel.localhost'};
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${process.env.PANEL_DOMAIN || 'panel.localhost'}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${process.env.PANEL_DOMAIN || 'panel.localhost'}/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy to Node.js application
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # WebSocket support
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files caching
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
`;
    
    await fs.writeFile('config/nginx-panel.conf', nginxConfig);
    console.log('✅ Configuração Nginx criada em config/nginx-panel.conf');
    
    // Criar arquivo de input CSS para Tailwind
    const inputCSS = `@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom styles */
@layer components {
  .btn {
    @apply inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-200;
  }
  
  .btn-primary {
    @apply btn bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500;
  }
  
  .btn-secondary {
    @apply btn bg-secondary-600 text-white hover:bg-secondary-700 focus:ring-secondary-500;
  }
  
  .btn-success {
    @apply btn bg-success-600 text-white hover:bg-success-700 focus:ring-success-500;
  }
  
  .btn-danger {
    @apply btn bg-danger-600 text-white hover:bg-danger-700 focus:ring-danger-500;
  }
  
  .card {
    @apply bg-white shadow-card rounded-lg;
  }
  
  .card-hover {
    @apply card hover:shadow-card-hover transition-shadow duration-200;
  }
}

/* Animation improvements */
@layer utilities {
  .animate-pulse-slow {
    animation: pulse 3s infinite;
  }
}
`;
    
    await fs.writeFile('public/assets/input.css', inputCSS);
    console.log('✅ Arquivo CSS base criado');
    
    // Script de deployment
    const deployScript = `#!/bin/bash

echo "🚀 Iniciando deployment do painel..."

# Atualizar dependências
npm install --production

# Build dos assets
npm run build:assets

# Configurar permissões
sudo chown -R www-data:www-data /var/www/panel
sudo chmod -R 755 /var/www/panel

# Copiar configuração do Nginx
sudo cp config/nginx-panel.conf /etc/nginx/sites-available/panel
sudo ln -sf /etc/nginx/sites-available/panel /etc/nginx/sites-enabled/

# Testar configuração do Nginx
sudo nginx -t

# Obter SSL se não existir
if [ ! -f "/etc/letsencrypt/live/$PANEL_DOMAIN/fullchain.pem" ]; then
    sudo certbot --nginx -d $PANEL_DOMAIN --non-interactive --agree-tos --email $CERTBOT_EMAIL
fi

# Reload Nginx
sudo systemctl reload nginx

# Iniciar aplicação com PM2
pm2 start ecosystem.config.js --env production

echo "✅ Deployment concluído!"
echo "🌐 Acesse: https://$PANEL_DOMAIN"
`;
    
    await fs.writeFile('scripts/deploy.sh', deployScript);
    await fs.chmod('scripts/deploy.sh', '755');
    console.log('✅ Script de deployment criado');
    
    console.log('\n🎉 Configuração concluída!\n');
    console.log('📋 Próximos passos:');
    console.log('1. npm install');
    console.log('2. npm run build:assets');
    console.log('3. ./scripts/deploy.sh');
    console.log('4. Configurar DNS do domínio para apontar para este servidor\n');
    
  } catch (error) {
    console.error('❌ Erro na configuração:', error.message);
  } finally {
    rl.close();
  }
}

setup();
