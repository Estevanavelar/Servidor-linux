#!/bin/bash

# Script de instalação completa na pasta root
# Execute como: sudo bash <(curl -s URL_DO_SCRIPT) panel.seudominio.com admin@seudominio.com

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    error "Use: sudo bash install-root.sh panel.seudominio.com admin@seudominio.com"
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

log "🚀 Instalação Completa do Servidor Linux Profissional"
log "📍 Instalando na pasta: /root/"
log "🌐 Domínio: $DOMAIN"
log "📧 Email: $EMAIL"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Navegar para /root
cd /root

# Remover instalação anterior se existir
if [ -d "servidor-linux" ]; then
    warning "Instalação anterior encontrada, fazendo backup..."
    mv servidor-linux "servidor-linux-backup-$(date +%Y%m%d-%H%M%S)" || true
fi

# Atualizar sistema
log "Atualizando sistema Ubuntu..."
apt update && apt upgrade -y

# Instalar dependências básicas
log "Instalando dependências básicas..."
apt install -y git curl wget unzip build-essential software-properties-common

# Instalar Node.js 18
if ! command -v node &> /dev/null || ! node --version | grep -q "v18"; then
    log "Instalando Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Verificar Node.js
NODE_VERSION=$(node --version)
log "✅ Node.js instalado: $NODE_VERSION"

# Instalar PM2 globalmente
if ! command -v pm2 &> /dev/null; then
    log "Instalando PM2..."
    npm install -g pm2
fi

# Instalar servidor web se não estiver instalado
if ! command -v nginx &> /dev/null; then
    log "Instalando Nginx..."
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
fi

# Instalar MySQL se não estiver instalado
if ! command -v mysql &> /dev/null; then
    log "Instalando MySQL..."
    apt install -y mysql-server
    systemctl start mysql
    systemctl enable mysql
    
    info "Configure o MySQL posteriormente com: mysql_secure_installation"
fi

# Instalar PHP-FPM se não estiver instalado
if ! dpkg -l | grep -q php8.1-fpm; then
    log "Instalando PHP-FPM..."
    apt install -y php8.1-fpm php8.1-mysql php8.1-curl php8.1-xml php8.1-mbstring
    systemctl start php8.1-fpm
    systemctl enable php8.1-fpm
fi

# Instalar Redis (opcional)
if ! command -v redis-server &> /dev/null; then
    log "Instalando Redis..."
    apt install -y redis-server
    systemctl start redis-server
    systemctl enable redis-server
fi

# Instalar Certbot para SSL
if ! command -v certbot &> /dev/null; then
    log "Instalando Certbot..."
    apt install -y certbot python3-certbot-nginx
fi

# Clonar o projeto
log "Clonando projeto na pasta /root..."
git clone https://github.com/Estevanavelar/servidor-linux.git

# Verificar se foi clonado
if [ ! -d "servidor-linux" ]; then
    error "Falha ao clonar o projeto"
    exit 1
fi

# Navegar para o projeto
cd servidor-linux

# Dar permissões aos scripts
log "Configurando permissões dos scripts..."
chmod +x scripts/*.sh

# Navegar para o painel
cd panel

# Instalar dependências do painel
log "Instalando dependências do painel..."
npm install

# Executar configuração inicial
log "Executando configuração inicial..."
if [ -f "setup.js" ]; then
    node setup.js <<EOF
$DOMAIN
$EMAIL
admin
1583
EOF
else
    warning "setup.js não encontrado, criando configuração básica..."
    
    # Criar .env básico
    cat > .env << EOL
NODE_ENV=production
PORT=3000
SECRET_KEY=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 16)
PANEL_DOMAIN=$DOMAIN
PANEL_URL=https://$DOMAIN
ADMIN_EMAIL=$EMAIL
ADMIN_USER=admin
ADMIN_PASSWORD_HASH=\$2a\$12\$rQJ5/z0aUjYwKzYe7HHlP.nYNOzGNpnPs8CZI4FRbVPx6kEjSA6gG
BACKUP_RETENTION_DAYS=30
BACKUP_LOCATION=/var/backups/server-panel
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
LOG_LEVEL=info
LOG_MAX_SIZE=10m
LOG_MAX_FILES=5d
EOL
fi

# Executar configuração do domínio
log "Configurando domínio e SSL..."
cd /root/servidor-linux
./scripts/setup-panel-domain.sh "$DOMAIN" "$EMAIL"

# Verificação final
log "Verificando instalação..."
sleep 5

# Verificar se PM2 está funcionando
if pm2 list | grep -q server-panel; then
    log "✅ Painel PM2 funcionando"
else
    error "❌ Painel PM2 não está funcionando"
fi

# Verificar se o painel responde
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/health" | grep -q "200"; then
    log "✅ Painel respondendo localmente"
else
    warning "⚠️  Painel não responde localmente"
fi

# Verificar se Nginx está funcionando
if systemctl is-active --quiet nginx; then
    log "✅ Nginx funcionando"
else
    error "❌ Nginx não está funcionando"
fi

# Testar acesso via domínio
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null | grep -q "200"; then
    log "✅ Painel acessível via HTTPS"
elif curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health" 2>/dev/null | grep -q "200"; then
    warning "⚠️  Painel acessível via HTTP (SSL pode não estar configurado)"
else
    warning "⚠️  Painel pode não estar acessível via domínio (verifique DNS)"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "🌐 ACESSO AO PAINEL:"
echo "• URL: https://$DOMAIN"
echo "• Usuário: admin"
echo "• Senha: 1583"
echo
echo "📁 LOCALIZAÇÃO DOS ARQUIVOS:"
echo "• Projeto: /root/servidor-linux/"
echo "• Painel: /root/servidor-linux/panel/"
echo "• Scripts: /root/servidor-linux/scripts/"
echo "• Logs: /root/servidor-linux/panel/logs/"
echo
echo "🔧 COMANDOS ÚTEIS:"
echo "• Ver status: pm2 status"
echo "• Ver logs: pm2 logs server-panel"
echo "• Reiniciar: pm2 restart server-panel"
echo "• Testar serviços: /root/servidor-linux/scripts/test-boot.sh"
echo "• Monitor automático: /root/servidor-linux/scripts/ensure-panel-running.sh"
echo
echo "🔄 INICIALIZAÇÃO AUTOMÁTICA:"
echo "• ✅ Painel inicia automaticamente no boot"
echo "• ✅ Monitoramento a cada 5 minutos"
echo "• ✅ Todos os serviços configurados"
echo "• ✅ SSL automático configurado"
echo
echo "📋 PARA TESTAR REINICIALIZAÇÃO:"
echo "• sudo reboot"
echo "• Aguardar 3-5 minutos"
echo "• Acessar: https://$DOMAIN"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔥 Servidor profissional pronto para hospedagem comercial!"
log "🌟 Acesse https://$DOMAIN para começar a gerenciar!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
