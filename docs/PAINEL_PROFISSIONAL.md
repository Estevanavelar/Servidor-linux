# 🚀 Painel Profissional - Hospedagem Comercial

## 📋 Visão Geral

O **Painel Profissional** é uma solução completa e moderna para gerenciamento de servidores Linux voltada para **hospedagem comercial**. Com interface responsiva, monitoramento em tempo real e recursos avançados.

## ✨ Funcionalidades Profissionais

### 🎛️ Dashboard Moderno
- **Interface Tailwind CSS** - Design moderno e responsivo
- **Gráficos em tempo real** - CPU, memória, disco com Chart.js
- **WebSocket** - Atualizações em tempo real
- **Notificações** - Sistema de alertas integrado

### 🌐 Gerenciamento de Hospedagem
- **Criação automática de sites** - Nginx + PHP opcional
- **SSL automático** - Let's Encrypt integrado
- **Multi-domínios** - Suporte completo a subdomínios
- **Gerenciador de arquivos** - Upload e navegação web

### 🔒 Segurança Avançada
- **Rate limiting** - Proteção contra ataques
- **Headers de segurança** - HSTS, CSP, XSS protection
- **Autenticação JWT** - Tokens seguros
- **Logs estruturados** - Winston com rotação diária

### 📊 Monitoramento
- **System Information** - CPU, memória, disco em tempo real
- **Status de serviços** - Nginx, MySQL, PHP-FPM, Redis
- **Logs centralizados** - Acesso aos logs do sistema
- **Alertas via email** - Notificações automáticas

### 💾 Backup Automático
- **Backup diário** - Sites, configs e bancos
- **Retenção configurável** - Limpeza automática de backups antigos
- **Compressão** - Arquivos tar.gz otimizados

## 🛠️ Instalação Completa

### Pré-requisitos
- **Ubuntu 20.04+** ou **Debian 10+**
- **Node.js 18+** e **npm**
- **Nginx**, **MySQL**, **PHP-FPM**
- **Domínio configurado** apontando para o servidor

### 1. Preparar o Sistema
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y git curl wget unzip build-essential

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar PM2 globalmente
sudo npm install -g pm2
```

### 2. Clonar e Configurar o Projeto
```bash
# Clonar repositório
git clone https://github.com/seu-usuario/servidor-linux.git
cd servidor-linux

# Navegar para o painel
cd panel

# Instalar dependências
npm install

# Executar configuração inicial
sudo node setup.js
```

### 3. Configurar Domínio e Inicialização Automática
```bash
# Dar permissões aos scripts
sudo chmod +x ../scripts/*.sh

# Configurar domínio (substitua pelos seus dados)
sudo ../scripts/setup-panel-domain.sh panel.seudominio.com admin@seudominio.com

# O script irá configurar:
# ✅ Nginx com SSL automático
# ✅ PM2 com inicialização no boot
# ✅ Todos os serviços para auto-start
# ✅ Monitoramento a cada 5 minutos
# ✅ Serviço systemd de backup
# ✅ Firewall e segurança
```

### 4. Verificação da Instalação
```bash
# Verificar status do painel
pm2 status

# Ver logs
pm2 logs server-panel

# Testar conectividade
curl https://panel.seudominio.com/health

# Verificar serviços
sudo systemctl status nginx mysql php8.1-fpm
```

## 🌐 Configuração de Domínio

### DNS Configuration
Para acessar o painel de qualquer lugar, configure seu DNS:

```
Tipo: A
Nome: panel (ou @)
IP: [IP-DO-SEU-SERVIDOR]
TTL: 300 (5 minutos)
```

### Cloudflare (Recomendado)
Se usar Cloudflare:

```
Tipo: A
Nome: panel
IP: [IP-DO-SERVIDOR]
Proxy: 🔴 DESABILITADO (nuvem cinza)
```

**⚠️ IMPORTANTE:** Para o painel de administração, sempre deixe o proxy **DESABILITADO**.

## 🔄 Inicialização Automática (Auto-Start)

### Sistema Robusto de Inicialização
O painel foi projetado para **sempre funcionar**, mesmo após reinicializações do servidor:

#### 1. **Múltiplas Camadas de Proteção**
- **PM2:** Gerenciador principal de processos
- **Systemd Service:** Backup na porta 3001 
- **Cron Monitoring:** Verifica a cada 5 minutos
- **Boot Check:** Verificação 2 minutos após boot

#### 2. **Serviços Configurados Automaticamente**
```bash
# Todos estes serviços iniciam no boot:
systemctl is-enabled nginx          # ✅ enabled
systemctl is-enabled mysql          # ✅ enabled  
systemctl is-enabled php8.1-fpm     # ✅ enabled
systemctl is-enabled redis-server   # ✅ enabled
systemctl is-enabled server-panel-backup # ✅ enabled
```

#### 3. **Monitoramento Contínuo**
```bash
# Verificar logs de monitoramento
tail -f /var/log/panel-monitor.log

# Testar manualmente
sudo ./scripts/ensure-panel-running.sh

# Ver status de todos os serviços
sudo ./scripts/test-boot.sh
```

#### 4. **Teste de Reinicialização**
```bash
# Para testar se funciona após reiniciar:
sudo reboot

# Aguardar 3-5 minutos, depois verificar:
curl https://panel.seudominio.com/health
pm2 status
sudo ./scripts/test-boot.sh
```

### Recuperação Automática
- **Painel para?** → Reinicia automaticamente em 30 segundos
- **Nginx para?** → Detecta e reinicia em 5 minutos
- **MySQL para?** → Detecta e tenta reiniciar
- **Servidor reinicia?** → Tudo volta online automaticamente

## ⚙️ Configurações Avançadas

### Variáveis de Ambiente (.env)
```bash
# Segurança
SECRET_KEY=sua-chave-super-secreta
SESSION_SECRET=chave-sessao

# Domínio
PANEL_DOMAIN=panel.seudominio.com
PANEL_URL=https://panel.seudominio.com

# Admin
ADMIN_EMAIL=admin@seudominio.com
ADMIN_USER=admin
ADMIN_PASSWORD_HASH=hash-bcrypt-da-senha

# Email (opcional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=seu-email@gmail.com
SMTP_PASS=sua-senha-app

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_LOCATION=/var/backups/server-panel

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
```

### Nginx Customizado
```nginx
# /etc/nginx/sites-available/panel-seudominio.com

server {
    listen 443 ssl http2;
    server_name panel.seudominio.com;
    
    # SSL via Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/panel.seudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/panel.seudominio.com/privkey.pem;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    # Proxy to Node.js
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
    }
}
```

## 🔧 Comandos de Gerenciamento

### PM2 (Process Manager)
```bash
# Status dos processos
pm2 status

# Ver logs em tempo real
pm2 logs server-panel

# Reiniciar painel
pm2 restart server-panel

# Parar painel
pm2 stop server-panel

# Monitoramento avançado
pm2 monit

# Salvar configuração
pm2 save

# Configurar inicialização automática
pm2 startup
```

### Nginx
```bash
# Testar configuração
sudo nginx -t

# Recarregar configuração
sudo systemctl reload nginx

# Reiniciar Nginx
sudo systemctl restart nginx

# Ver logs
sudo tail -f /var/log/nginx/panel-seudominio.com-access.log
sudo tail -f /var/log/nginx/panel-seudominio.com-error.log
```

### SSL/Let's Encrypt
```bash
# Renovar certificados
sudo certbot renew

# Renovar domínio específico
sudo certbot --nginx -d panel.seudominio.com

# Listar certificados
sudo certbot certificates

# Testar renovação automática
sudo certbot renew --dry-run
```

## 📊 Uso do Painel

### Login
- **URL:** https://panel.seudominio.com
- **Usuário:** admin (configurável)
- **Senha:** definida durante setup

### Funcionalidades Principais

#### 1. Dashboard
- Visão geral do sistema
- Gráficos de CPU e memória
- Status dos serviços
- Estatísticas de sites

#### 2. Gerenciar Hospedagem
- Criar novos sites
- Configurar domínios
- Habilitar PHP
- Upload de arquivos

#### 3. Certificados SSL
- Obter SSL automático
- Renovação automática
- Status dos certificados

#### 4. Bancos de Dados
- Acesso MySQL/PostgreSQL
- Gerenciamento via web
- Backup automático

#### 5. Monitoramento
- Logs em tempo real
- Alertas de sistema
- Performance monitoring

## 🔐 Segurança

### Medidas Implementadas
- **Rate Limiting:** 100 requests/15min
- **HTTPS obrigatório** com HSTS
- **Headers de segurança** (CSP, XSS, etc.)
- **JWT com expiração** (24h)
- **Logs de auditoria**
- **Firewall configurado**

### Recomendações Adicionais
```bash
# Alterar porta SSH (opcional)
sudo nano /etc/ssh/sshd_config
# Port 2222

# Configurar Fail2Ban
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Backup das chaves SSH
sudo cp -r ~/.ssh/ /backup/ssh-keys/

# Monitoramento de intrusão
sudo apt install rkhunter chkrootkit
```

## 🚨 Troubleshooting

### Problemas Comuns

#### Painel não acessa via domínio
```bash
# Verificar DNS
nslookup panel.seudominio.com

# Verificar Nginx
sudo nginx -t
sudo systemctl status nginx

# Verificar PM2
pm2 status
pm2 logs server-panel

# Verificar portas
sudo netstat -tlnp | grep :3000
```

#### SSL não funciona
```bash
# Verificar certificado
sudo certbot certificates

# Renovar manualmente
sudo certbot --nginx -d panel.seudominio.com

# Verificar DNS
dig panel.seudominio.com

# Testar conectividade
curl -I https://panel.seudominio.com
```

#### Performance lenta
```bash
# Verificar recursos
htop
df -h
free -h

# Verificar logs
pm2 logs server-panel --lines 100

# Reiniciar serviços
sudo systemctl restart nginx
pm2 restart server-panel
```

### Logs Importantes
```bash
# Logs do painel
tail -f panel/logs/application-*.log
tail -f panel/logs/error-*.log

# Logs do Nginx
tail -f /var/log/nginx/panel-*-access.log
tail -f /var/log/nginx/panel-*-error.log

# Logs do sistema
journalctl -u nginx -f
journalctl -f
```

## 📈 Monitoramento e Manutenção

### Backup Automático
O sistema faz backup diário às 02:00:
- **Sites:** /var/www → /var/backups/server-panel/sites-YYYY-MM-DD.tar.gz
- **Configs:** /etc/nginx → /var/backups/server-panel/nginx-YYYY-MM-DD.tar.gz
- **Banco:** MySQL dump → /var/backups/server-panel/mysql-YYYY-MM-DD.sql

### Manutenção Programada
```bash
# Adicionar ao crontab do root
sudo crontab -e

# Backup adicional semanal
0 3 * * 0 /usr/local/bin/backup-completo.sh

# Limpeza de logs antigos
0 4 * * * find /var/log -name "*.log" -type f -mtime +30 -delete

# Verificação de segurança
0 5 * * * rkhunter --check --report-warnings-only
```

### Atualização do Painel
```bash
# Script automático criado durante instalação
sudo /usr/local/bin/update-panel

# Ou manualmente:
cd /caminho/do/projeto/panel
git pull origin main
npm install --production
pm2 restart server-panel
sudo systemctl reload nginx
```

## 🎯 Otimização para Produção

### Performance
```bash
# Otimizar MySQL
sudo mysql_secure_installation

# Configurar Redis para cache
sudo apt install redis-server
sudo systemctl enable redis

# Configurar compressão Nginx
sudo nano /etc/nginx/nginx.conf
# gzip on;
# gzip_types text/css application/javascript;
```

### Scaling
```bash
# Multiple instances com PM2
pm2 start server-new.js -i max --name "server-panel-cluster"

# Load balancer Nginx
upstream panel_backend {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
    server 127.0.0.1:3002;
}
```

## 💼 Uso Comercial

### Multi-tenancy
- Cada cliente pode ter subdomínio
- Isolamento de arquivos e bancos
- Quotas personalizáveis
- Faturamento integrado (futuro)

### White Label
- Logo personalizável
- Cores personalizáveis
- Domínio próprio
- Branding completo

---

## 🏆 Resultado Final

Com essa configuração, você terá:

✅ **Painel moderno e profissional**  
✅ **Acesso seguro via HTTPS de qualquer lugar**  
✅ **Monitoramento em tempo real**  
✅ **Backup automático diário**  
✅ **SSL automático para novos sites**  
✅ **Interface responsiva para mobile**  
✅ **Logs estruturados e alertas**  
✅ **Pronto para uso comercial**  

**🔥 Seu servidor está pronto para competir com soluções como cPanel, mas completamente personalizado!**
