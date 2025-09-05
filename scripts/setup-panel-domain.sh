#!/bin/bash

# Script para configurar acesso ao painel via domínio
# Uso: ./setup-panel-domain.sh panel.seudominio.com admin@seudominio.com

set -e

# Configuração para instalação em /root/
SCRIPT_DIR="/root/servidor-linux/scripts"
PROJECT_DIR="/root/servidor-linux"
PANEL_DIR="/root/servidor-linux/panel"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar se é executado como root
if [[ $EUID -ne 0 ]]; then
    error "Este script deve ser executado como root"
    exit 1
fi

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <dominio> <email>"
    echo "Exemplo: $0 panel.seudominio.com admin@seudominio.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
PANEL_PORT=${3:-3000}

log "🚀 Configurando Painel Profissional para domínio: $DOMAIN"

# Verificar se o domínio resolve para este servidor
info "Verificando DNS do domínio..."
DOMAIN_IP=$(dig +short $DOMAIN | tail -1)
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    warning "ATENÇÃO: O domínio $DOMAIN não aponta para este servidor!"
    warning "IP do domínio: $DOMAIN_IP"
    warning "IP do servidor: $SERVER_IP"
    echo -n "Deseja continuar mesmo assim? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        error "Configuração cancelada. Configure o DNS primeiro."
        exit 1
    fi
fi

# Verificar se o Nginx está instalado e rodando
if ! command -v nginx &> /dev/null; then
    error "Nginx não está instalado. Execute primeiro o script de instalação."
    exit 1
fi

if ! systemctl is-active --quiet nginx; then
    log "Iniciando Nginx..."
    systemctl start nginx
    systemctl enable nginx
fi

# Criar configuração do Nginx para o painel
log "Criando configuração Nginx para o painel..."

NGINX_CONFIG="/etc/nginx/sites-available/panel-$DOMAIN"

cat > "$NGINX_CONFIG" << EOF
# Professional Server Panel - Nginx Configuration
# Domain: $DOMAIN
# Generated: $(date)

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;
    
    # SSL Configuration (will be updated by Certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Modern SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Security Headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.tailwindcss.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; img-src 'self' data: https:; connect-src 'self' ws: wss:;" always;
    
    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=panel_limit:10m rate=10r/m;
    limit_req zone=panel_limit burst=20 nodelay;
    
    # Proxy to Node.js application
    location / {
        proxy_pass http://127.0.0.1:$PANEL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
    
    # Socket.IO support
    location /socket.io/ {
        proxy_pass http://127.0.0.1:$PANEL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API endpoints with additional security
    location /api/ {
        proxy_pass http://127.0.0.1:$PANEL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Additional rate limiting for API
        limit_req zone=panel_limit burst=5 nodelay;
    }
    
    # Static files with caching
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://127.0.0.1:$PANEL_PORT;
        proxy_set_header Host \$host;
        
        # Caching headers
        expires 1M;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
        
        # GZIP
        gzip on;
        gzip_vary on;
        gzip_types text/css application/javascript image/svg+xml;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:$PANEL_PORT;
        access_log off;
    }
    
    # Deny access to sensitive files
    location ~ /\\.(ht|git|env) {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Logging
    access_log /var/log/nginx/panel-$DOMAIN-access.log;
    error_log /var/log/nginx/panel-$DOMAIN-error.log;
}
EOF

log "Configuração Nginx criada: $NGINX_CONFIG"

# Habilitar o site
log "Habilitando site no Nginx..."
ln -sf "$NGINX_CONFIG" "/etc/nginx/sites-enabled/panel-$DOMAIN"

# Testar configuração do Nginx
log "Testando configuração do Nginx..."
if ! nginx -t; then
    error "Erro na configuração do Nginx"
    exit 1
fi

# Recarregar Nginx
log "Recarregando Nginx..."
systemctl reload nginx

# Verificar se o Certbot está instalado
if ! command -v certbot &> /dev/null; then
    log "Instalando Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# Obter certificado SSL
log "Obtendo certificado SSL para $DOMAIN..."
if certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --redirect; then
    log "✅ Certificado SSL obtido com sucesso!"
else
    warning "Falha ao obter certificado SSL. O site funcionará apenas via HTTP."
    warning "Você pode tentar novamente depois com: certbot --nginx -d $DOMAIN"
fi

# Configurar renovação automática do SSL
log "Configurando renovação automática do SSL..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Configurar monitoramento automático do painel
log "Configurando monitoramento automático do painel..."
chmod +x "$SCRIPT_DIR/ensure-panel-running.sh"
chmod +x "$SCRIPT_DIR/test-boot.sh"

# Adicionar ao crontab para verificar a cada 5 minutos
(crontab -l 2>/dev/null; echo "*/5 * * * * /root/servidor-linux/scripts/ensure-panel-running.sh") | crontab -

# Adicionar verificação no boot (aguardar 2 minutos após boot)
(crontab -l 2>/dev/null; echo "@reboot sleep 120 && /root/servidor-linux/scripts/ensure-panel-running.sh") | crontab -

# Criar serviço systemd de backup para o painel
log "Criando serviço systemd de backup..."
SYSTEMD_SERVICE="/etc/systemd/system/server-panel-backup.service"
cat > "$SYSTEMD_SERVICE" << EOF
[Unit]
Description=Server Panel Backup Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$PANEL_DIR
ExecStart=/usr/bin/node $PANEL_DIR/server-new.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3001

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=server-panel-backup

[Install]
WantedBy=multi-user.target
EOF

# Habilitar serviço de backup (port 3001)
systemctl daemon-reload
systemctl enable server-panel-backup

log "✅ Serviço systemd de backup criado na porta 3001"

# Verificar se PM2 está instalado
if ! command -v pm2 &> /dev/null; then
    log "Instalando PM2..."
    npm install -g pm2
fi

# Navegar para o diretório do painel
cd "$PANEL_DIR"

# Instalar dependências se necessário
if [ ! -d "node_modules" ]; then
    log "Instalando dependências do painel..."
    npm install
fi

# Criar arquivo .env se não existir
if [ ! -f ".env" ]; then
    log "Executando configuração inicial..."
    node setup.js
fi

# Atualizar variáveis de ambiente
log "Atualizando configurações de domínio..."
if [ -f ".env" ]; then
    sed -i "s|^PANEL_DOMAIN=.*|PANEL_DOMAIN=$DOMAIN|" .env
    sed -i "s|^PANEL_URL=.*|PANEL_URL=https://$DOMAIN|" .env
    sed -i "s|^CERTBOT_EMAIL=.*|CERTBOT_EMAIL=$EMAIL|" .env
    sed -i "s|^PORT=.*|PORT=$PANEL_PORT|" .env
else
    error "Arquivo .env não encontrado. Execute primeiro: node setup.js"
    exit 1
fi

# Iniciar/reiniciar o painel com PM2
log "Iniciando painel profissional..."
pm2 delete server-panel 2>/dev/null || true
pm2 start server-new.js --name "server-panel" --env production

# Salvar configuração do PM2
pm2 save

# Configurar PM2 para inicialização automática no boot
log "Configurando inicialização automática do PM2..."
PM2_STARTUP_CMD=$(pm2 startup | tail -1)
if [[ $PM2_STARTUP_CMD == *"sudo"* ]]; then
    eval "$PM2_STARTUP_CMD"
    pm2 save
    log "✅ PM2 configurado para iniciar automaticamente no boot"
else
    warning "Não foi possível configurar inicialização automática do PM2"
fi

# Configurar serviços essenciais para iniciar no boot
log "Configurando serviços para inicialização automática..."

# Nginx
systemctl enable nginx
log "✅ Nginx habilitado para inicialização automática"

# MySQL
systemctl enable mysql
log "✅ MySQL habilitado para inicialização automática"

# PHP-FPM
systemctl enable php8.1-fpm
log "✅ PHP-FPM habilitado para inicialização automática"

# Redis (se instalado)
if systemctl list-unit-files | grep -q redis; then
    systemctl enable redis-server
    log "✅ Redis habilitado para inicialização automática"
fi

# PostgreSQL (se instalado)
if systemctl list-unit-files | grep -q postgresql; then
    systemctl enable postgresql
    log "✅ PostgreSQL habilitado para inicialização automática"
fi

# Verificar status do painel
sleep 3
if pm2 show server-panel > /dev/null 2>&1; then
    log "✅ Painel iniciado com sucesso!"
else
    error "Falha ao iniciar o painel. Verifique os logs: pm2 logs server-panel"
    exit 1
fi

# Configurar firewall se o UFW estiver ativo
if systemctl is-active --quiet ufw; then
    log "Configurando firewall..."
    ufw allow 'Nginx Full'
    ufw allow ssh
    ufw --force enable
fi

# Criar script de atualização
log "Criando script de atualização..."
UPDATE_SCRIPT="/usr/local/bin/update-panel"
cat > "$UPDATE_SCRIPT" << 'EOF'
#!/bin/bash
# Script de atualização do painel profissional

cd /root/servidor-linux

# Pull latest changes
git pull origin main

# Update dependencies
cd panel
npm install --production

# Build assets if needed
npm run build 2>/dev/null || true

# Restart PM2
pm2 restart server-panel

# Reload Nginx
systemctl reload nginx

echo "✅ Painel atualizado com sucesso!"
EOF

chmod +x "$UPDATE_SCRIPT"

# Resumo final
log "🎉 Configuração concluída com sucesso!"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 PAINEL PROFISSIONAL CONFIGURADO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🔗 URL de Acesso: https://$DOMAIN"
echo "👤 Usuário Admin: $(grep ADMIN_USER .env | cut -d'=' -f2 || echo 'admin')"
echo "🔐 SSL: $([ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && echo "✅ Ativo" || echo "❌ Não configurado")"
echo "🚀 Status: $(pm2 show server-panel > /dev/null 2>&1 && echo "✅ Online" || echo "❌ Offline")"
echo
echo "📋 COMANDOS ÚTEIS:"
echo "• Ver logs: pm2 logs server-panel"
echo "• Reiniciar: pm2 restart server-panel"
echo "• Status: pm2 status"
echo "• Atualizar: $UPDATE_SCRIPT"
echo "• SSL renovar: certbot --nginx -d $DOMAIN"
echo
echo "🔄 INICIALIZAÇÃO AUTOMÁTICA:"
echo "• PM2: $(systemctl is-enabled pm2-root 2>/dev/null || echo "✅ Configurado via startup script")"
echo "• Systemd Backup: $(systemctl is-enabled server-panel-backup 2>/dev/null || echo "❌")"
echo "• Nginx: $(systemctl is-enabled nginx)"
echo "• MySQL: $(systemctl is-enabled mysql)"
echo "• PHP-FPM: $(systemctl is-enabled php8.1-fpm)"
echo "• Redis: $(systemctl is-enabled redis-server 2>/dev/null || echo "N/A")"
echo
echo "🔍 MONITORAMENTO AUTOMÁTICO:"
echo "• Verificação a cada 5 minutos via cron"
echo "• Reinício automático do painel se parar"
echo "• Verificação após boot do sistema"
echo "• Logs em: /var/log/panel-monitor.log"
echo "• Serviço backup na porta 3001"
echo
echo "📁 ARQUIVOS IMPORTANTES:"
echo "• Projeto: /root/servidor-linux/"
echo "• Painel: /root/servidor-linux/panel/"
echo "• Scripts: /root/servidor-linux/scripts/"
echo "• Nginx config: $NGINX_CONFIG"
echo "• Logs painel: /root/servidor-linux/panel/logs/"
echo "• Logs Nginx: /var/log/nginx/panel-$DOMAIN-*.log"
echo "• PM2 startup: ~/.pm2/dump.pm2"
echo
echo "🔄 TESTE INICIALIZAÇÃO:"
echo "• sudo reboot (reiniciar servidor para testar)"
echo "• /root/servidor-linux/scripts/test-boot.sh (testar serviços)"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar se tudo está funcionando
info "Verificando funcionamento..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PANEL_PORT/health" | grep -q "200"; then
    log "✅ Painel respondendo corretamente na porta $PANEL_PORT"
else
    error "❌ Painel não está respondendo. Verifique os logs: pm2 logs server-panel"
fi

if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null | grep -q "200"; then
    log "✅ Painel acessível via HTTPS"
elif curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health" 2>/dev/null | grep -q "200"; then
    log "⚠️  Painel acessível via HTTP (SSL pode não estar configurado)"
else
    error "❌ Painel não está acessível via domínio. Verifique DNS e configurações."
fi

echo
log "🔥 Painel profissional está pronto para hospedagem comercial!"
log "🌟 Acesse https://$DOMAIN para começar a gerenciar seus sites!"
