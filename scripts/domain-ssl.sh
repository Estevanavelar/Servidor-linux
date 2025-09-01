#!/bin/bash

# ================================================
# 🌐 Script para Configuração de Domínios e SSL
# ================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Função para criar um novo site
create_site() {
    local domain=$1
    local webroot=$2
    local enable_php=$3
    
    if [[ -z "$domain" ]]; then
        error "Domínio é obrigatório"
        echo "Uso: $0 create-site <dominio> [diretorio] [php]"
        exit 1
    fi
    
    # Definir diretório padrão
    if [[ -z "$webroot" ]]; then
        webroot="/var/www/$domain"
    fi
    
    log "Criando site para $domain..."
    
    # Criar diretório do site
    mkdir -p "$webroot"
    chown -R www-data:www-data "$webroot"
    chmod -R 755 "$webroot"
    
    # Configuração do Nginx
    local config_file="/etc/nginx/sites-available/$domain"
    
    cat > "$config_file" << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $domain www.$domain;
    root $webroot;
    index index.html index.htm$([ "$enable_php" = "yes" ] && echo " index.php");
    
    # Logs
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
EOF

    # Adicionar configuração PHP se solicitado
    if [[ "$enable_php" = "yes" ]]; then
        cat >> "$config_file" << EOF
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
EOF
    fi

    cat >> "$config_file" << EOF
    
    # Deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
    
    # Deny access to sensitive files
    location ~* \.(env|log|conf)$ {
        deny all;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # Habilitar site
    ln -sf "$config_file" "/etc/nginx/sites-enabled/"
    
    # Testar configuração
    if nginx -t; then
        systemctl reload nginx
        log "Site $domain criado e habilitado com sucesso!"
    else
        error "Erro na configuração do Nginx"
        exit 1
    fi
    
    # Criar página de teste
    if [[ ! -f "$webroot/index.html" ]]; then
        cat > "$webroot/index.html" << EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bem-vindo ao $domain</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background: #f4f4f4; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .status { background: #27ae60; color: white; padding: 20px; border-radius: 5px; text-align: center; margin: 20px 0; }
        .info { background: #ecf0f1; padding: 20px; border-radius: 5px; }
        .next-steps { background: #3498db; color: white; padding: 20px; border-radius: 5px; }
        code { background: #f8f9fa; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Site $domain Configurado!</h1>
        
        <div class="status">
            ✅ Seu site está funcionando corretamente
        </div>
        
        <div class="info">
            <h3>📋 Informações do Site:</h3>
            <p><strong>Domínio:</strong> $domain</p>
            <p><strong>Diretório:</strong> <code>$webroot</code></p>
            <p><strong>PHP:</strong> $([ "$enable_php" = "yes" ] && echo "Habilitado" || echo "Desabilitado")</p>
            <p><strong>Configuração:</strong> <code>$config_file</code></p>
        </div>
        
        <div class="next-steps">
            <h3>🚀 Próximos Passos:</h3>
            <ol>
                <li>Faça upload dos seus arquivos para <code>$webroot</code></li>
                <li>Configure seu DNS para apontar para este servidor</li>
                <li>Execute: <code>sudo bash domain-ssl.sh install-ssl $domain seu@email.com</code></li>
                <li>Acesse o painel de controle para gerenciar visualmente</li>
            </ol>
        </div>
    </div>
</body>
</html>
EOF
        chown www-data:www-data "$webroot/index.html"
    fi
    
    log "📁 Diretório do site: $webroot"
    log "⚙️  Configuração: $config_file"
    log "🌐 Teste o site em: http://$domain"
}

# Função para instalar SSL
install_ssl() {
    local domain=$1
    local email=$2
    
    if [[ -z "$domain" ]] || [[ -z "$email" ]]; then
        error "Domínio e email são obrigatórios"
        echo "Uso: $0 install-ssl <dominio> <email>"
        exit 1
    fi
    
    log "Instalando certificado SSL para $domain..."
    
    # Verificar se o certbot está instalado
    if ! command -v certbot &> /dev/null; then
        log "Instalando Certbot..."
        if command -v apt &> /dev/null; then
            apt update
            apt install -y certbot python3-certbot-nginx
        elif command -v yum &> /dev/null; then
            yum install -y certbot python3-certbot-nginx
        fi
    fi
    
    # Verificar se o domínio resolve para este servidor
    local server_ip=$(curl -s ifconfig.me)
    local domain_ip=$(dig +short $domain | tail -n1)
    
    if [[ "$domain_ip" != "$server_ip" ]]; then
        warning "O domínio $domain não aponta para este servidor ($server_ip)"
        warning "IP do domínio: $domain_ip"
        warning "Certifique-se de que o DNS está configurado corretamente"
        
        read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Obter certificado SSL
    if certbot --nginx -d "$domain" -d "www.$domain" --email "$email" --agree-tos --non-interactive --redirect; then
        log "✅ Certificado SSL instalado com sucesso para $domain!"
        
        # Configurar renovação automática
        setup_ssl_renewal
        
        log "🔒 Site agora disponível em: https://$domain"
    else
        error "Falha ao obter certificado SSL"
        exit 1
    fi
}

# Configurar renovação automática de SSL
setup_ssl_renewal() {
    log "Configurando renovação automática de SSL..."
    
    # Adicionar cron job se não existir
    if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -
        log "✅ Renovação automática configurada (todo dia às 3h)"
    fi
}

# Função para renovar SSL
renew_ssl() {
    log "Renovando certificados SSL..."
    
    if certbot renew --quiet; then
        systemctl reload nginx
        log "✅ Certificados renovados com sucesso!"
    else
        error "Erro ao renovar certificados"
        exit 1
    fi
}

# Função para listar sites
list_sites() {
    log "📋 Sites configurados:"
    echo
    
    for site in /etc/nginx/sites-available/*; do
        if [[ -f "$site" ]] && [[ "$(basename "$site")" != "default" ]]; then
            local site_name=$(basename "$site")
            local enabled="❌"
            
            if [[ -L "/etc/nginx/sites-enabled/$site_name" ]]; then
                enabled="✅"
            fi
            
            local ssl="❌"
            if [[ -d "/etc/letsencrypt/live/$site_name" ]]; then
                ssl="🔒"
            fi
            
            echo "  $site_name $enabled $ssl"
        fi
    done
    
    echo
    echo "Legenda: ✅ Habilitado | ❌ Desabilitado | 🔒 SSL Ativo"
}

# Função para remover site
remove_site() {
    local domain=$1
    
    if [[ -z "$domain" ]]; then
        error "Domínio é obrigatório"
        echo "Uso: $0 remove-site <dominio>"
        exit 1
    fi
    
    warning "Esta ação irá remover completamente o site $domain"
    read -p "Tem certeza? Digite 'sim' para confirmar: " confirm
    
    if [[ "$confirm" = "sim" ]]; then
        # Desabilitar site
        rm -f "/etc/nginx/sites-enabled/$domain"
        
        # Mover configuração para lixeira
        mkdir -p /.lixeira/nginx-sites
        mv "/etc/nginx/sites-available/$domain" "/.lixeira/nginx-sites/$domain.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
        
        # Mover diretório do site para lixeira
        if [[ -d "/var/www/$domain" ]]; then
            mkdir -p /.lixeira/www
            mv "/var/www/$domain" "/.lixeira/www/$domain.$(date +%Y%m%d-%H%M%S)"
        fi
        
        # Remover certificado SSL
        if [[ -d "/etc/letsencrypt/live/$domain" ]]; then
            certbot delete --cert-name "$domain" --non-interactive
        fi
        
        # Recarregar Nginx
        nginx -t && systemctl reload nginx
        
        log "✅ Site $domain removido com sucesso!"
    else
        log "Operação cancelada"
    fi
}

# Função principal
main() {
    case "$1" in
        "create-site")
            check_root
            create_site "$2" "$3" "$4"
            ;;
        "install-ssl")
            check_root
            install_ssl "$2" "$3"
            ;;
        "renew-ssl")
            check_root
            renew_ssl
            ;;
        "list-sites")
            list_sites
            ;;
        "remove-site")
            check_root
            remove_site "$2"
            ;;
        *)
            echo "🌐 Script de Gerenciamento de Domínios e SSL"
            echo
            echo "Uso:"
            echo "  $0 create-site <dominio> [diretorio] [php]"
            echo "  $0 install-ssl <dominio> <email>"
            echo "  $0 renew-ssl"
            echo "  $0 list-sites"
            echo "  $0 remove-site <dominio>"
            echo
            echo "Exemplos:"
            echo "  $0 create-site meusite.com"
            echo "  $0 create-site meusite.com /var/www/meusite yes"
            echo "  $0 install-ssl meusite.com admin@meusite.com"
            echo "  $0 list-sites"
            echo "  $0 remove-site meusite.com"
            ;;
    esac
}

# Executar função principal
main "$@"
