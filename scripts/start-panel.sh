#!/bin/bash

# ================================================
# 🎛️ Script para Iniciar o Painel de Controle
# ================================================

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Verificar Node.js
check_nodejs() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Node.js não encontrado. Execute primeiro o script de instalação.${NC}"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}npm não encontrado. Execute primeiro o script de instalação.${NC}"
        exit 1
    fi
}

# Ir para o diretório do painel
cd "$(dirname "$0")/../panel"

log "🚀 Iniciando painel de controle do servidor..."

# Verificar dependências
check_nodejs

# Instalar dependências se necessário
if [ ! -d "node_modules" ]; then
    log "📦 Instalando dependências..."
    npm install
fi

# Criar diretórios necessários
log "📁 Criando diretórios necessários..."
sudo mkdir -p /backups
sudo mkdir -p /var/log/server-panel

# Configurar variáveis de ambiente
export PORT=8080
export SECRET_KEY="servidor-linux-panel-$(date +%s)"

# Verificar se a porta está disponível
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    log "⚠️  Porta 8080 já está em uso. Tentando parar processo existente..."
    sudo pkill -f "node.*server.js" || true
    sleep 2
fi

# Iniciar o painel
log "🎛️ Iniciando painel de controle..."
log "📊 URL de acesso: http://$(curl -s ifconfig.me):8080"
log "📊 URL local: http://localhost:8080"
log "👤 Login padrão: admin / admin123"
log "🛑 Para parar o painel, pressione Ctrl+C"

# Verificar se PM2 está disponível para produção
if command -v pm2 &> /dev/null; then
    log "🔄 Usando PM2 para gerenciamento de processos..."
    pm2 stop server-panel 2>/dev/null || true
    pm2 start server.js --name "server-panel" --watch
    pm2 logs server-panel
else
    log "🔄 Iniciando em modo desenvolvimento..."
    node server.js
fi
