#!/bin/bash

# Script para garantir que o painel esteja sempre funcionando
# Pode ser executado via cron para máxima disponibilidade
# Uso: ./ensure-panel-running.sh

set -e

# Configurações
PANEL_NAME="server-panel"
PANEL_SCRIPT="server-new.js"
PANEL_PORT=3000
MAX_RESTART_ATTEMPTS=3
LOG_FILE="/var/log/panel-monitor.log"

# Função de log
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Verificar se é executado como root
if [[ $EUID -ne 0 ]]; then
    log_message "ERROR: Script deve ser executado como root"
    exit 1
fi

log_message "INFO: Iniciando verificação do painel..."

# Verificar se PM2 está instalado
if ! command -v pm2 &> /dev/null; then
    log_message "ERROR: PM2 não está instalado"
    exit 1
fi

# Verificar se o processo existe no PM2
if ! pm2 list | grep -q "$PANEL_NAME"; then
    log_message "WARNING: Painel não encontrado no PM2, iniciando..."
    
    # Diretório do painel na pasta root
    PANEL_DIR="/root/servidor-linux/panel"
    
    if [ -d "$PANEL_DIR" ]; then
        cd "$PANEL_DIR"
        
        # Iniciar o painel
        if pm2 start "$PANEL_SCRIPT" --name "$PANEL_NAME" --env production; then
            pm2 save
            log_message "SUCCESS: Painel iniciado com sucesso"
        else
            log_message "ERROR: Falha ao iniciar painel"
            exit 1
        fi
    else
        log_message "ERROR: Diretório do painel não encontrado: $PANEL_DIR"
        exit 1
    fi
fi

# Verificar se o painel está online
if pm2 list | grep "$PANEL_NAME" | grep -q "online"; then
    log_message "INFO: Painel está online no PM2"
else
    log_message "WARNING: Painel existe mas não está online, reiniciando..."
    
    if pm2 restart "$PANEL_NAME"; then
        sleep 5
        if pm2 list | grep "$PANEL_NAME" | grep -q "online"; then
            log_message "SUCCESS: Painel reiniciado com sucesso"
        else
            log_message "ERROR: Falha ao reiniciar painel"
            exit 1
        fi
    else
        log_message "ERROR: Falha ao reiniciar painel via PM2"
        exit 1
    fi
fi

# Verificar se o painel responde na porta
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PANEL_PORT/health" | grep -q "200"; then
    log_message "SUCCESS: Painel respondendo corretamente na porta $PANEL_PORT"
else
    log_message "WARNING: Painel não responde na porta $PANEL_PORT"
    
    # Tentar reiniciar mais algumas vezes
    for i in $(seq 1 $MAX_RESTART_ATTEMPTS); do
        log_message "INFO: Tentativa $i de $MAX_RESTART_ATTEMPTS para reiniciar painel"
        
        pm2 restart "$PANEL_NAME"
        sleep 10
        
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PANEL_PORT/health" | grep -q "200"; then
            log_message "SUCCESS: Painel funcionando após tentativa $i"
            break
        else
            if [ $i -eq $MAX_RESTART_ATTEMPTS ]; then
                log_message "ERROR: Painel não responde após $MAX_RESTART_ATTEMPTS tentativas"
                
                # Log dos erros do PM2
                log_message "PM2 LOGS:"
                pm2 logs "$PANEL_NAME" --lines 20 >> "$LOG_FILE" 2>&1
                
                exit 1
            fi
        fi
    done
fi

# Verificar serviços essenciais
check_service() {
    local service_name=$1
    
    if systemctl is-active --quiet "$service_name"; then
        log_message "INFO: Serviço $service_name está rodando"
        return 0
    else
        log_message "WARNING: Serviço $service_name não está rodando, tentando iniciar..."
        
        if systemctl start "$service_name"; then
            sleep 2
            if systemctl is-active --quiet "$service_name"; then
                log_message "SUCCESS: Serviço $service_name iniciado com sucesso"
                return 0
            else
                log_message "ERROR: Falha ao iniciar serviço $service_name"
                return 1
            fi
        else
            log_message "ERROR: Comando para iniciar $service_name falhou"
            return 1
        fi
    fi
}

# Verificar serviços essenciais
CRITICAL_SERVICES=("nginx" "mysql" "php8.1-fpm")
FAILED_SERVICES=()

for service in "${CRITICAL_SERVICES[@]}"; do
    if ! check_service "$service"; then
        FAILED_SERVICES+=("$service")
    fi
done

# Verificar Nginx especificamente para o proxy do painel
if systemctl is-active --quiet nginx; then
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost" 2>/dev/null | grep -q -E "(200|301|302|404)"; then
        log_message "INFO: Nginx proxy funcionando"
    else
        log_message "WARNING: Nginx rodando mas não respondendo, recarregando..."
        if nginx -t && systemctl reload nginx; then
            log_message "SUCCESS: Nginx recarregado"
        else
            log_message "ERROR: Falha ao recarregar Nginx"
            FAILED_SERVICES+=("nginx-proxy")
        fi
    fi
fi

# Relatório final
if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    log_message "SUCCESS: Todos os serviços estão funcionando corretamente"
    exit 0
else
    log_message "ERROR: Serviços com problema: ${FAILED_SERVICES[*]}"
    
    # Tentar notificar por email se configurado
    if [ -n "$ADMIN_EMAIL" ] && command -v mail &> /dev/null; then
        echo "Serviços com problema no servidor: ${FAILED_SERVICES[*]}" | \
        mail -s "Alerta: Problemas no servidor $(hostname)" "$ADMIN_EMAIL"
    fi
    
    exit 1
fi
