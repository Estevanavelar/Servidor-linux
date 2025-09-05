#!/bin/bash

# Script para testar inicialização automática dos serviços
# Uso: ./test-boot.sh

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

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se é executado como root
if [[ $EUID -ne 0 ]]; then
    error "Este script deve ser executado como root"
    exit 1
fi

log "🔍 Testando Configuração de Inicialização Automática"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Status dos serviços essenciais
SERVICES=(
    "nginx"
    "mysql" 
    "php8.1-fpm"
)

# Serviços opcionais
OPTIONAL_SERVICES=(
    "redis-server"
    "postgresql"
)

echo "🔄 VERIFICANDO STATUS DOS SERVIÇOS:"
echo

# Verificar serviços essenciais
for service in "${SERVICES[@]}"; do
    if systemctl is-enabled "$service" &>/dev/null; then
        if systemctl is-active "$service" &>/dev/null; then
            success "$service - Habilitado e Rodando"
        else
            fail "$service - Habilitado mas PARADO"
            systemctl status "$service" --no-pager -l
        fi
    else
        fail "$service - NÃO HABILITADO para inicialização automática"
        echo "   Execute: sudo systemctl enable $service"
    fi
done

# Verificar serviços opcionais
for service in "${OPTIONAL_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        if systemctl is-enabled "$service" &>/dev/null; then
            if systemctl is-active "$service" &>/dev/null; then
                success "$service - Habilitado e Rodando"
            else
                warning "$service - Habilitado mas parado"
            fi
        else
            info "$service - Instalado mas não habilitado"
        fi
    else
        info "$service - Não instalado"
    fi
done

echo
echo "🔄 VERIFICANDO PM2 E PAINEL:"
echo

# Verificar PM2
if command -v pm2 &> /dev/null; then
    success "PM2 instalado"
    
    # Verificar configuração de startup
    if [ -f ~/.pm2/dump.pm2 ]; then
        success "PM2 dump.pm2 existe"
    else
        fail "PM2 dump.pm2 NÃO EXISTE - Execute: pm2 save"
    fi
    
    # Verificar se PM2 está configurado no systemd
    if systemctl list-unit-files | grep -q pm2; then
        success "PM2 systemd service configurado"
    else
        warning "PM2 systemd service pode não estar configurado"
        echo "   Execute: pm2 startup e siga as instruções"
    fi
    
    # Verificar processos PM2
    if pm2 list | grep -q server-panel; then
        if pm2 list | grep server-panel | grep -q online; then
            success "Painel server-panel rodando no PM2"
        else
            fail "Painel server-panel existe mas está OFFLINE"
            pm2 show server-panel
        fi
    else
        fail "Painel server-panel NÃO ENCONTRADO no PM2"
        echo "   Execute: pm2 start server-new.js --name server-panel"
    fi
else
    fail "PM2 não está instalado"
fi

echo
echo "🌐 VERIFICANDO CONECTIVIDADE:"
echo

# Verificar se o painel responde
PANEL_PORT=${1:-3000}
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PANEL_PORT/health" | grep -q "200"; then
    success "Painel respondendo na porta $PANEL_PORT"
else
    fail "Painel NÃO RESPONDE na porta $PANEL_PORT"
    echo "   Verifique: pm2 logs server-panel"
fi

# Verificar Nginx
if curl -s -o /dev/null -w "%{http_code}" "http://localhost/health" 2>/dev/null | grep -q "200"; then
    success "Nginx proxy funcionando"
elif curl -s -o /dev/null -w "%{http_code}" "http://localhost" 2>/dev/null | grep -q -E "(200|301|302)"; then
    success "Nginx respondendo (pode não ter proxy do painel configurado)"
else
    fail "Nginx não está respondendo"
fi

echo
echo "🔐 VERIFICANDO FIREWALL:"
echo

# Verificar UFW
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        success "UFW firewall ativo"
        
        if ufw status | grep -q "Nginx Full"; then
            success "Regras Nginx configuradas no firewall"
        else
            warning "Regras Nginx podem não estar configuradas"
            echo "   Execute: sudo ufw allow 'Nginx Full'"
        fi
        
        if ufw status | grep -q "22"; then
            success "Acesso SSH permitido no firewall"
        else
            warning "Acesso SSH pode estar bloqueado"
        fi
    else
        info "UFW firewall não está ativo"
    fi
else
    info "UFW não está instalado"
fi

echo
echo "📊 INFORMAÇÕES DO SISTEMA:"
echo

# Uptime
echo "⏱️  Uptime: $(uptime -p)"

# Load average
echo "📈 Load Average: $(cat /proc/loadavg | cut -d' ' -f1-3)"

# Memory usage
MEM_INFO=$(free -h | grep Mem)
echo "🧠 Memória: $MEM_INFO"

# Disk usage
echo "💾 Disco:"
df -h / | grep -v Filesystem

echo
echo "🔄 SIMULANDO TESTE DE BOOT:"
echo

# Listar serviços habilitados
echo "Serviços habilitados para inicialização:"
systemctl list-unit-files --state=enabled --type=service | grep -E "(nginx|mysql|php|redis|postgresql|pm2)" || echo "   Nenhum serviço relacionado encontrado"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Contagem de problemas
ISSUES=0

# Verificar problemas críticos
if ! systemctl is-active --quiet nginx; then
    ((ISSUES++))
fi

if ! systemctl is-active --quiet mysql; then
    ((ISSUES++))
fi

if ! pm2 list | grep server-panel | grep -q online; then
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo
    success "🎉 TODOS OS SERVIÇOS ESTÃO OK!"
    success "✅ O servidor está pronto para reiniciar automaticamente!"
    echo
    info "Para testar de verdade:"
    info "1. sudo reboot"
    info "2. Aguarde alguns minutos"
    info "3. Acesse https://seu-dominio.com"
    info "4. Execute este script novamente após o boot"
else
    echo
    fail "⚠️  ENCONTRADOS $ISSUES PROBLEMAS!"
    fail "❌ Corrija os problemas antes de reiniciar o servidor"
    echo
    echo "💡 DICAS PARA CORRIGIR:"
    echo "• systemctl enable <servico>"
    echo "• systemctl start <servico>"
    echo "• pm2 startup && pm2 save"
    echo "• pm2 start server-new.js --name server-panel"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Para mais informações:"
echo "• Logs PM2: pm2 logs server-panel"
echo "• Status serviços: systemctl status <servico>"
echo "• Logs sistema: journalctl -f"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
