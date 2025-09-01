#!/bin/bash

# ================================================
# 🚀 Script de Instalação Completa do Servidor
# ================================================
# Autor: Sistema Automatizado
# Descrição: Instala e configura tudo necessário para um servidor Linux completo
# Suporte: Ubuntu 20.04+, Debian 10+, CentOS 8+

set -e  # Para em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Detectar distribuição Linux
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        DIST=$ID
        VER=$VERSION_ID
    else
        error "Sistema operacional não suportado"
        exit 1
    fi
}

# Verificar se é executado como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script deve ser executado como root (use sudo)"
        exit 1
    fi
}

# Atualizar sistema
update_system() {
    log "Atualizando sistema..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt update && apt upgrade -y
        apt install -y wget curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum update -y
        yum install -y wget curl gnupg2 epel-release
    fi
}

# Instalar Nginx
install_nginx() {
    log "Instalando Nginx..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y nginx
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y nginx
    fi
    
    systemctl enable nginx
    systemctl start nginx
    
    # Configuração básica do Nginx
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # Criar estrutura de diretórios
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /var/www/html
    
    # Site padrão
    cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.php;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    
    log "Nginx instalado e configurado com sucesso!"
}

# Instalar Node.js e TypeScript
install_nodejs() {
    log "Instalando Node.js e TypeScript..."
    
    # Instalar NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y nodejs
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y nodejs npm
    fi
    
    # Instalar packages globais
    npm install -g typescript ts-node pm2 yarn
    
    log "Node.js $(node --version) e TypeScript instalados!"
}

# Instalar PHP
install_php() {
    log "Instalando PHP 8.1..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        add-apt-repository ppa:ondrej/php -y
        apt update
        apt install -y php8.1 php8.1-fpm php8.1-mysql php8.1-pgsql php8.1-sqlite3 \
                       php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip \
                       php8.1-bcmath php8.1-intl php8.1-redis php8.1-imagick
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y php php-fpm php-mysql php-pgsql php-sqlite php-curl \
                       php-gd php-mbstring php-xml php-zip php-bcmath php-intl
    fi
    
    systemctl enable php8.1-fpm
    systemctl start php8.1-fpm
    
    log "PHP 8.1 instalado e configurado!"
}

# Instalar Python
install_python() {
    log "Instalando Python 3.9+ e pip..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y python3 python3-pip python3-venv python3-dev
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y python3 python3-pip python3-devel
    fi
    
    # Instalar ferramentas essenciais
    pip3 install --upgrade pip setuptools wheel virtualenv
    
    log "Python $(python3 --version) instalado!"
}

# Instalar bancos de dados
install_databases() {
    log "Instalando bancos de dados..."
    
    # MySQL
    log "Instalando MySQL..."
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y mysql-server mysql-client
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y mysql-server mysql
    fi
    systemctl enable mysql
    systemctl start mysql
    
    # PostgreSQL
    log "Instalando PostgreSQL..."
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y postgresql postgresql-contrib
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y postgresql-server postgresql-contrib
        postgresql-setup initdb
    fi
    systemctl enable postgresql
    systemctl start postgresql
    
    # SQLite (já vem instalado geralmente)
    log "Verificando SQLite..."
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y sqlite3
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y sqlite
    fi
    
    log "Bancos de dados instalados!"
}

# Configurar SSH
configure_ssh() {
    log "Configurando SSH e segurança..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y openssh-server fail2ban ufw
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y openssh-server fail2ban firewalld
    fi
    
    # Configuração SSH mais segura
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    cat > /etc/ssh/sshd_config << 'EOF'
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024

SyslogFacility AUTH
LogLevel INFO

LoginGraceTime 120
PermitRootLogin no
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes

IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no

PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes

X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes

MaxStartups 10:30:60
Banner /etc/issue.net

Subsystem sftp /usr/lib/openssh/sftp-server
EOF

    systemctl enable ssh
    systemctl restart ssh
    
    # Configurar Fail2Ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

    systemctl enable fail2ban
    systemctl start fail2ban
    
    log "SSH configurado com segurança!"
}

# Instalar ferramentas adicionais
install_tools() {
    log "Instalando ferramentas adicionais..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        apt install -y git vim nano htop nload iotop tree zip unzip \
                       certbot python3-certbot-nginx redis-server
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        yum install -y git vim nano htop nload iotop tree zip unzip \
                       certbot python3-certbot-nginx redis
    fi
    
    systemctl enable redis
    systemctl start redis
    
    log "Ferramentas adicionais instaladas!"
}

# Configurar firewall
configure_firewall() {
    log "Configurando firewall..."
    
    if [[ "$DIST" == "ubuntu" ]] || [[ "$DIST" == "debian" ]]; then
        ufw --force enable
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 'Nginx Full'
        ufw allow 3306  # MySQL
        ufw allow 5432  # PostgreSQL
    elif [[ "$DIST" == "centos" ]] || [[ "$DIST" == "rhel" ]]; then
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=3306/tcp
        firewall-cmd --permanent --add-port=5432/tcp
        firewall-cmd --reload
    fi
    
    log "Firewall configurado!"
}

# Função principal
main() {
    log "🚀 Iniciando instalação completa do servidor..."
    
    check_root
    detect_os
    
    log "Sistema detectado: $OS ($DIST $VER)"
    
    update_system
    install_nginx
    install_nodejs
    install_php
    install_python
    install_databases
    configure_ssh
    install_tools
    configure_firewall
    
    # Criar página de teste
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>🚀 Servidor Configurado com Sucesso!</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .status { background: #2ecc71; color: white; padding: 10px; border-radius: 5px; margin: 10px 0; }
        .service { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Servidor Linux Configurado com Sucesso!</h1>
        <div class="status">✅ Instalação completa realizada</div>
        
        <h2>📋 Serviços Instalados:</h2>
        <div class="service">🌐 <strong>Nginx</strong> - Servidor web</div>
        <div class="service">🟢 <strong>Node.js + TypeScript</strong> - Runtime JavaScript</div>
        <div class="service">🐘 <strong>PHP 8.1</strong> - Linguagem de programação</div>
        <div class="service">🐍 <strong>Python 3</strong> - Linguagem de programação</div>
        <div class="service">🗄️ <strong>MySQL</strong> - Banco de dados</div>
        <div class="service">🐘 <strong>PostgreSQL</strong> - Banco de dados</div>
        <div class="service">📁 <strong>SQLite</strong> - Banco de dados leve</div>
        <div class="service">🔒 <strong>SSH + Fail2Ban</strong> - Acesso seguro</div>
        <div class="service">🔥 <strong>Firewall</strong> - Proteção de rede</div>
        <div class="service">📦 <strong>Redis</strong> - Cache em memória</div>
        
        <h2>🎯 Próximos Passos:</h2>
        <ol>
            <li>Acesse o painel de controle em: <code>http://SEU-IP:8080</code></li>
            <li>Configure seus domínios e SSL</li>
            <li>Faça upload dos seus projetos</li>
        </ol>
    </div>
</body>
</html>
EOF

    log "✅ Instalação completa finalizada com sucesso!"
    log "🌐 Acesse http://$(curl -s ifconfig.me) para ver a página de teste"
    log "📊 Execute o painel de controle com: ./scripts/start-panel.sh"
}

# Executar função principal
main "$@"
