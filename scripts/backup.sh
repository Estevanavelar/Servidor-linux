#!/bin/bash

# ================================================
# 💾 Script de Backup Automatizado
# ================================================

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configurações
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)
RETENTION_DAYS=30

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] AVISO: $1${NC}"
}

# Verificar se é executado como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script deve ser executado como root (use sudo)"
        exit 1
    fi
}

# Criar diretório de backup
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    chmod 755 "$BACKUP_DIR"
}

# Backup dos sites
backup_websites() {
    log "Fazendo backup dos sites..."
    
    if [ -d "/var/www" ]; then
        tar -czf "$BACKUP_DIR/sites-$DATE.tar.gz" \
            -C /var \
            www \
            --exclude="*.log" \
            --exclude="*.tmp" \
            2>/dev/null || true
        
        log "✅ Sites salvos em: sites-$DATE.tar.gz"
    else
        warning "Diretório /var/www não encontrado"
    fi
}

# Backup das configurações do Nginx
backup_nginx() {
    log "Fazendo backup das configurações do Nginx..."
    
    if [ -d "/etc/nginx" ]; then
        tar -czf "$BACKUP_DIR/nginx-$DATE.tar.gz" \
            -C /etc \
            nginx \
            2>/dev/null || true
        
        log "✅ Configurações Nginx salvas em: nginx-$DATE.tar.gz"
    else
        warning "Diretório /etc/nginx não encontrado"
    fi
}

# Backup dos bancos MySQL
backup_mysql() {
    log "Fazendo backup dos bancos MySQL..."
    
    if command -v mysqldump &> /dev/null; then
        # Listar todos os bancos exceto os do sistema
        DATABASES=$(mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")
        
        if [ ! -z "$DATABASES" ]; then
            mkdir -p "$BACKUP_DIR/mysql-$DATE"
            
            for db in $DATABASES; do
                log "Fazendo backup do banco: $db"
                mysqldump --single-transaction --routines --triggers "$db" > "$BACKUP_DIR/mysql-$DATE/$db.sql" 2>/dev/null || true
            done
            
            # Compactar todos os backups MySQL
            tar -czf "$BACKUP_DIR/mysql-$DATE.tar.gz" -C "$BACKUP_DIR" "mysql-$DATE"
            rm -rf "$BACKUP_DIR/mysql-$DATE"
            
            log "✅ Bancos MySQL salvos em: mysql-$DATE.tar.gz"
        else
            log "Nenhum banco MySQL para backup"
        fi
    else
        warning "MySQL não está instalado"
    fi
}

# Backup dos bancos PostgreSQL
backup_postgresql() {
    log "Fazendo backup dos bancos PostgreSQL..."
    
    if command -v pg_dumpall &> /dev/null; then
        sudo -u postgres pg_dumpall > "$BACKUP_DIR/postgresql-$DATE.sql" 2>/dev/null || true
        gzip "$BACKUP_DIR/postgresql-$DATE.sql"
        
        log "✅ Bancos PostgreSQL salvos em: postgresql-$DATE.sql.gz"
    else
        warning "PostgreSQL não está instalado"
    fi
}

# Backup dos certificados SSL
backup_ssl() {
    log "Fazendo backup dos certificados SSL..."
    
    if [ -d "/etc/letsencrypt" ]; then
        tar -czf "$BACKUP_DIR/ssl-$DATE.tar.gz" \
            -C /etc \
            letsencrypt \
            2>/dev/null || true
        
        log "✅ Certificados SSL salvos em: ssl-$DATE.tar.gz"
    else
        log "Nenhum certificado SSL encontrado"
    fi
}

# Backup das configurações do sistema
backup_system_configs() {
    log "Fazendo backup das configurações do sistema..."
    
    mkdir -p "$BACKUP_DIR/configs-$DATE"
    
    # Arquivos importantes do sistema
    cp -r /etc/ssh "$BACKUP_DIR/configs-$DATE/" 2>/dev/null || true
    cp -r /etc/fail2ban "$BACKUP_DIR/configs-$DATE/" 2>/dev/null || true
    cp /etc/mysql/mysql.conf.d/mysqld.cnf "$BACKUP_DIR/configs-$DATE/" 2>/dev/null || true
    cp /etc/postgresql/*/main/postgresql.conf "$BACKUP_DIR/configs-$DATE/" 2>/dev/null || true
    cp /etc/php/*/fpm/php.ini "$BACKUP_DIR/configs-$DATE/" 2>/dev/null || true
    
    # Compactar configurações
    tar -czf "$BACKUP_DIR/configs-$DATE.tar.gz" -C "$BACKUP_DIR" "configs-$DATE"
    rm -rf "$BACKUP_DIR/configs-$DATE"
    
    log "✅ Configurações do sistema salvas em: configs-$DATE.tar.gz"
}

# Backup do painel de controle
backup_panel() {
    log "Fazendo backup do painel de controle..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PANEL_DIR="$(dirname "$SCRIPT_DIR")/panel"
    
    if [ -d "$PANEL_DIR" ]; then
        tar -czf "$BACKUP_DIR/panel-$DATE.tar.gz" \
            -C "$(dirname "$PANEL_DIR")" \
            "$(basename "$PANEL_DIR")" \
            --exclude="node_modules" \
            --exclude="*.log" \
            2>/dev/null || true
        
        log "✅ Painel de controle salvo em: panel-$DATE.tar.gz"
    else
        warning "Diretório do painel não encontrado"
    fi
}

# Limpar backups antigos
cleanup_old_backups() {
    log "Limpando backups antigos (mais de $RETENTION_DAYS dias)..."
    
    if [ -d "$BACKUP_DIR" ]; then
        find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
        
        log "✅ Limpeza de backups antigos concluída"
    fi
}

# Gerar relatório de backup
generate_report() {
    log "Gerando relatório de backup..."
    
    REPORT_FILE="$BACKUP_DIR/backup-report-$DATE.txt"
    
    cat > "$REPORT_FILE" << EOF
============================================
RELATÓRIO DE BACKUP - $(date)
============================================

Data/Hora: $(date)
Servidor: $(hostname)
Usuário: $(whoami)

ARQUIVOS CRIADOS:
EOF

    # Listar arquivos criados hoje
    find "$BACKUP_DIR" -name "*$DATE*" -type f -exec ls -lh {} \; >> "$REPORT_FILE"
    
    cat >> "$REPORT_FILE" << EOF

ESPAÇO TOTAL USADO:
$(du -sh "$BACKUP_DIR")

ESPAÇO DISPONÍVEL:
$(df -h "$BACKUP_DIR")

STATUS DOS SERVIÇOS:
$(systemctl is-active nginx mysql postgresql redis php8.1-fpm 2>/dev/null || echo "Alguns serviços podem não estar instalados")

============================================
EOF

    log "✅ Relatório salvo em: backup-report-$DATE.txt"
}

# Enviar backup para armazenamento remoto (opcional)
upload_to_remote() {
    local remote_path="$1"
    
    if [ ! -z "$remote_path" ]; then
        log "Enviando backups para armazenamento remoto..."
        
        # Exemplo com rsync (descomente e configure)
        # rsync -avz "$BACKUP_DIR/*$DATE*" "$remote_path"
        
        # Exemplo com AWS S3 (descomente e configure)
        # aws s3 sync "$BACKUP_DIR" s3://seu-bucket/backups/
        
        log "⚠️  Upload remoto não configurado. Edite o script para habilitar."
    fi
}

# Função de restore
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        error "Especifique o arquivo de backup para restaurar"
        echo "Uso: $0 restore /backups/sites-20240101-120000.tar.gz"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Arquivo de backup não encontrado: $backup_file"
        exit 1
    fi
    
    warning "ATENÇÃO: Esta operação irá sobrescrever arquivos existentes!"
    read -p "Tem certeza que deseja continuar? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Restaurando backup: $backup_file"
        
        # Determinar tipo de backup pelo nome
        if [[ "$backup_file" == *"sites-"* ]]; then
            tar -xzf "$backup_file" -C /var/
            chown -R www-data:www-data /var/www
        elif [[ "$backup_file" == *"nginx-"* ]]; then
            tar -xzf "$backup_file" -C /etc/
            systemctl reload nginx
        elif [[ "$backup_file" == *"mysql-"* ]]; then
            # Descompactar e restaurar
            tar -xzf "$backup_file" -C /tmp/
            mysql_dir=$(basename "$backup_file" .tar.gz)
            for sql_file in /tmp/$mysql_dir/*.sql; do
                if [ -f "$sql_file" ]; then
                    db_name=$(basename "$sql_file" .sql)
                    mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
                    mysql "$db_name" < "$sql_file"
                fi
            done
            rm -rf "/tmp/$mysql_dir"
        fi
        
        log "✅ Backup restaurado com sucesso!"
    else
        log "Operação cancelada"
    fi
}

# Função principal
main() {
    case "$1" in
        "full")
            check_root
            create_backup_dir
            log "🚀 Iniciando backup completo..."
            backup_websites
            backup_nginx
            backup_mysql
            backup_postgresql
            backup_ssl
            backup_system_configs
            backup_panel
            cleanup_old_backups
            generate_report
            upload_to_remote "$2"
            log "✅ Backup completo finalizado!"
            log "📁 Arquivos salvos em: $BACKUP_DIR"
            ;;
        "sites")
            check_root
            create_backup_dir
            backup_websites
            ;;
        "databases")
            check_root
            create_backup_dir
            backup_mysql
            backup_postgresql
            ;;
        "configs")
            check_root
            create_backup_dir
            backup_nginx
            backup_ssl
            backup_system_configs
            ;;
        "restore")
            check_root
            restore_backup "$2"
            ;;
        "list")
            if [ -d "$BACKUP_DIR" ]; then
                log "📋 Backups disponíveis:"
                ls -lah "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "Nenhum backup encontrado"
            else
                log "Diretório de backup não existe"
            fi
            ;;
        *)
            echo "💾 Script de Backup Automatizado"
            echo
            echo "Uso:"
            echo "  $0 full [remote_path]    - Backup completo"
            echo "  $0 sites                 - Backup apenas dos sites"
            echo "  $0 databases             - Backup apenas dos bancos"
            echo "  $0 configs               - Backup apenas das configurações"
            echo "  $0 restore <arquivo>     - Restaurar backup específico"
            echo "  $0 list                  - Listar backups disponíveis"
            echo
            echo "Exemplos:"
            echo "  $0 full"
            echo "  $0 sites"
            echo "  $0 restore /backups/sites-20240101-120000.tar.gz"
            echo "  $0 list"
            ;;
    esac
}

# Executar função principal
main "$@"
