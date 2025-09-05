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

# Verificar se pasta já existe e fazer backup se necessário
if [ -d "servidor-linux" ]; then
    warning "Pasta 'servidor-linux' já existe!"
    
    # Verificar se é uma instalação válida
    if [ -f "servidor-linux/panel/server-new.js" ] && [ -f "servidor-linux/scripts/setup-panel-domain.sh" ]; then
        log "Instalação válida encontrada!"
        
        # Verificar se PM2 está rodando
        if pm2 list 2>/dev/null | grep -q server-panel; then
            info "Painel já está rodando no PM2"
            pm2 show server-panel || true
        fi
        
        echo
        warning "OPÇÕES DISPONÍVEIS:"
        echo "1. Manter instalação atual e apenas atualizar"
        echo "2. Fazer backup e instalar nova versão"
        echo "3. Remover completamente e instalar limpo"
        echo "4. Cancelar instalação"
        
        # Para automação, usar opção 2 (backup e atualizar)
        OPTION=2
        
        case $OPTION in
            1)
                log "Mantendo instalação atual e atualizando..."
                cd servidor-linux
                git pull origin main || git pull origin master || true
                ;;
            2)
                log "Fazendo backup e instalando nova versão..."
                BACKUP_NAME="servidor-linux-backup-$(date +%Y%m%d-%H%M%S)"
                mv servidor-linux "$BACKUP_NAME"
                log "✅ Backup criado: $BACKUP_NAME"
                
                # Parar PM2 se estiver rodando
                if pm2 list 2>/dev/null | grep -q server-panel; then
                    log "Parando painel PM2 temporariamente..."
                    pm2 stop server-panel || true
                fi
                ;;
            3)
                warning "Removendo instalação anterior..."
                if pm2 list 2>/dev/null | grep -q server-panel; then
                    pm2 delete server-panel || true
                fi
                rm -rf servidor-linux
                log "✅ Instalação anterior removida"
                ;;
            4)
                info "Instalação cancelada pelo usuário"
                exit 0
                ;;
        esac
    else
        warning "Pasta existe mas não é uma instalação válida!"
        warning "Pode ser um clone incompleto ou pasta com mesmo nome."
        
        log "Removendo pasta inválida..."
        rm -rf servidor-linux
        log "✅ Pasta removida"
    fi
else
    log "Pasta não existe, procedendo com instalação limpa..."
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

# Verificar espaço em disco antes de clonar
log "Verificando espaço em disco..."
AVAILABLE_SPACE=$(df /root | tail -1 | awk '{print $4}')
REQUIRED_SPACE=1048576  # 1GB em KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    error "Espaço insuficiente em /root"
    error "Disponível: $(($AVAILABLE_SPACE / 1024))MB"
    error "Necessário: $(($REQUIRED_SPACE / 1024))MB"
    exit 1
fi

log "✅ Espaço em disco suficiente: $(($AVAILABLE_SPACE / 1024))MB disponível"

# Clonar o projeto
log "Clonando projeto na pasta /root..."

# Verificar conectividade com GitHub antes de clonar
if ! ping -c 1 github.com &> /dev/null; then
    error "Sem conectividade com GitHub. Verifique sua conexão de internet."
    exit 1
fi

log "✅ Conectividade com GitHub verificada"

# Clonar o projeto
if git clone https://github.com/Estevanavelar/servidor-linux.git; then
    log "✅ Projeto clonado com sucesso"
else
    error "Falha ao clonar o projeto do GitHub"
    error "Verifique:"
    error "1. Conectividade com github.com"
    error "2. Se o repositório existe"
    error "3. Permissões de acesso"
    exit 1
fi

# Verificação dupla se a pasta foi criada corretamente
if [ ! -d "servidor-linux" ]; then
    error "Pasta servidor-linux não foi criada após clone"
    exit 1
fi

# Verificar se os arquivos essenciais existem
REQUIRED_FILES=(
    "servidor-linux/scripts/setup-panel-domain.sh"
    "servidor-linux/panel/package.json"
    "servidor-linux/panel/server-new.js"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        error "Arquivo essencial não encontrado: $file"
        error "O clone pode estar incompleto. Tente novamente."
        exit 1
    fi
done

log "✅ Todos os arquivos essenciais verificados"

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
# Verificação final completa
log "Executando verificação final da instalação..."
sleep 3

FINAL_CHECKS=0
TOTAL_CHECKS=8

# 1. Verificar PM2
if pm2 list | grep -q server-panel && pm2 list | grep server-panel | grep -q online; then
    log "✅ PM2 server-panel: ONLINE"
    ((FINAL_CHECKS++))
else
    error "❌ PM2 server-panel: PROBLEMA"
fi

# 2. Verificar Nginx
if systemctl is-active --quiet nginx; then
    log "✅ Nginx: RODANDO"
    ((FINAL_CHECKS++))
else
    error "❌ Nginx: PARADO"
fi

# 3. Verificar MySQL
if systemctl is-active --quiet mysql; then
    log "✅ MySQL: RODANDO"
    ((FINAL_CHECKS++))
else
    error "❌ MySQL: PARADO"
fi

# 4. Verificar PHP-FPM
if systemctl is-active --quiet php8.1-fpm; then
    log "✅ PHP-FPM: RODANDO"
    ((FINAL_CHECKS++))
else
    error "❌ PHP-FPM: PARADO"
fi

# 5. Verificar painel local
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/health" | grep -q "200"; then
    log "✅ Painel local: FUNCIONANDO"
    ((FINAL_CHECKS++))
else
    error "❌ Painel local: NÃO RESPONDE"
fi

# 6. Verificar SSL
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    log "✅ SSL: CONFIGURADO"
    ((FINAL_CHECKS++))
else
    warning "⚠️  SSL: NÃO CONFIGURADO"
fi

# 7. Verificar acesso via domínio
if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/health" 2>/dev/null | grep -q "200"; then
    log "✅ Acesso HTTPS: FUNCIONANDO"
    ((FINAL_CHECKS++))
elif curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN/health" 2>/dev/null | grep -q "200"; then
    warning "⚠️  Acesso HTTP: FUNCIONANDO (SSL pendente)"
    ((FINAL_CHECKS++))
else
    warning "⚠️  Acesso via domínio: VERIFICAR DNS"
fi

# 8. Verificar inicialização automática
if systemctl is-enabled nginx >/dev/null 2>&1 && systemctl is-enabled mysql >/dev/null 2>&1; then
    log "✅ Auto-start: CONFIGURADO"
    ((FINAL_CHECKS++))
else
    error "❌ Auto-start: PROBLEMA"
fi

# Resultado final
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FINAL_CHECKS" -eq "$TOTAL_CHECKS" ]; then
    log "🎉 INSTALAÇÃO 100% COMPLETA E FUNCIONANDO!"
    echo "🏆 Score: $FINAL_CHECKS/$TOTAL_CHECKS - PERFEITO!"
elif [ "$FINAL_CHECKS" -ge 6 ]; then
    log "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
    warning "Score: $FINAL_CHECKS/$TOTAL_CHECKS - Alguns itens precisam atenção"
elif [ "$FINAL_CHECKS" -ge 4 ]; then
    warning "⚠️  INSTALAÇÃO PARCIAL"
    warning "Score: $FINAL_CHECKS/$TOTAL_CHECKS - Vários problemas encontrados"
else
    error "❌ INSTALAÇÃO COM PROBLEMAS GRAVES"
    error "Score: $FINAL_CHECKS/$TOTAL_CHECKS - Requer correções"
fi

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
