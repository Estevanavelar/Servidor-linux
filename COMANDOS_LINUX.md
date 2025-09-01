# 🐧 Comandos para Executar no Servidor Linux

> **Importante:** Este projeto foi desenvolvido no Windows, mas é destinado para execução em servidores Linux. Os comandos abaixo devem ser executados no seu servidor Linux.

## 🚀 Instalação Completa

### 1. Preparar o Sistema
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# Instalar Git (se não tiver)
sudo apt install git -y                # Ubuntu/Debian
sudo yum install git -y                # CentOS/RHEL
```

### 2. Baixar o Projeto
```bash
# Opção 1: Clone via Git
git clone https://github.com/seu-usuario/servidor-linux.git
cd servidor-linux

# Opção 2: Download direto (se disponível)
wget https://github.com/seu-usuario/servidor-linux/archive/main.zip
unzip main.zip
cd servidor-linux-main
```

### 3. Dar Permissões aos Scripts
```bash
# Dar permissão de execução para todos os scripts
chmod +x scripts/*.sh

# Verificar permissões
ls -la scripts/
```

### 4. Executar Instalação Completa
```bash
# EXECUTAR COMO ROOT/SUDO
sudo ./scripts/install-server.sh
```

**⏱️ Aguarde 15-30 minutos para instalação completa**

### 5. Iniciar Painel de Controle
```bash
# Iniciar painel web
./scripts/start-panel.sh
```

## 🌐 URLs de Acesso

```bash
# Descobrir IP do servidor
curl ifconfig.me

# Acessar painel de controle
# http://SEU-IP:8080
```

**Credenciais padrão:**
- **Usuário:** `admin`
- **Senha:** `admin123`

## 🔧 Comandos de Gerenciamento

### Gerenciar Sites
```bash
# Criar site básico
sudo ./scripts/domain-ssl.sh create-site meusite.com

# Criar site com PHP
sudo ./scripts/domain-ssl.sh create-site meusite.com /var/www/meusite yes

# Listar sites
./scripts/domain-ssl.sh list-sites

# Remover site
sudo ./scripts/domain-ssl.sh remove-site meusite.com
```

### Gerenciar SSL
```bash
# Instalar certificado SSL
sudo ./scripts/domain-ssl.sh install-ssl meusite.com admin@meusite.com

# Renovar certificados
sudo ./scripts/domain-ssl.sh renew-ssl
```

### Sistema de Backup
```bash
# Backup completo
sudo ./scripts/backup.sh full

# Backup apenas sites
sudo ./scripts/backup.sh sites

# Backup apenas bancos
sudo ./scripts/backup.sh databases

# Listar backups
./scripts/backup.sh list

# Restaurar backup
sudo ./scripts/backup.sh restore /backups/sites-20240109-120000.tar.gz
```

### Gerenciar Painel
```bash
# Iniciar painel
./scripts/start-panel.sh

# Parar painel (se usando PM2)
pm2 stop server-panel

# Reiniciar painel
pm2 restart server-panel

# Ver logs do painel
pm2 logs server-panel
```

## 🔍 Comandos de Verificação

### Status dos Serviços
```bash
# Verificar todos os serviços
sudo systemctl status nginx mysql postgresql redis php8.1-fpm

# Verificar portas abertas
sudo ss -tuln | grep -E ':(22|80|443|3306|5432|6379|8080)'

# Verificar processos
htop
```

### Verificar Versões Instaladas
```bash
# Nginx
nginx -v

# Node.js e npm
node --version
npm --version

# PHP
php --version

# Python
python3 --version

# MySQL
mysql --version

# PostgreSQL
psql --version
```

### Logs do Sistema
```bash
# Logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs do MySQL
sudo tail -f /var/log/mysql/error.log

# Logs do sistema
sudo tail -f /var/log/syslog

# Logs do painel (se usando PM2)
pm2 logs server-panel
```

## 🔒 Configurações de Segurança

### SSH
```bash
# Editar configuração SSH
sudo nano /etc/ssh/sshd_config

# Reiniciar SSH
sudo systemctl restart ssh
```

### Firewall
```bash
# Ubuntu/Debian (UFW)
sudo ufw status
sudo ufw allow 8080  # Permitir porta do painel

# CentOS/RHEL (Firewalld)
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Fail2Ban
```bash
# Status do Fail2Ban
sudo fail2ban-client status

# Status específico do SSH
sudo fail2ban-client status sshd

# Desbanir IP
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

## 🗄️ Gerenciar Bancos de Dados

### MySQL
```bash
# Acessar console MySQL
sudo mysql -u root -p

# Configuração segura inicial
sudo mysql_secure_installation

# Criar banco e usuário
mysql -u root -p -e "
CREATE DATABASE meuapp;
CREATE USER 'meuusuario'@'localhost' IDENTIFIED BY 'minhasenha';
GRANT ALL PRIVILEGES ON meuapp.* TO 'meuusuario'@'localhost';
FLUSH PRIVILEGES;
"
```

### PostgreSQL
```bash
# Acessar console PostgreSQL
sudo -u postgres psql

# Criar banco e usuário
sudo -u postgres createuser --interactive meuusuario
sudo -u postgres createdb -O meuusuario meuapp
```

## 📁 Gerenciar Arquivos

### Upload de Arquivos
```bash
# Via SCP (do seu computador para o servidor)
scp -r meusite/* usuario@servidor:/var/www/meusite.com/

# Via rsync
rsync -avz meusite/ usuario@servidor:/var/www/meusite.com/

# Dar permissões corretas
sudo chown -R www-data:www-data /var/www/meusite.com
sudo chmod -R 755 /var/www/meusite.com
```

### Navegação
```bash
# Ir para diretório dos sites
cd /var/www

# Listar sites
ls -la /var/www/

# Editar arquivo
sudo nano /var/www/meusite.com/index.html
```

## 🔄 Manutenção

### Atualizações
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# Atualizar Node.js packages globais
sudo npm update -g

# Limpar sistema
sudo apt autoremove && sudo apt autoclean  # Ubuntu/Debian
```

### Monitoramento
```bash
# Uso de recursos
htop          # Processos e CPU
df -h         # Espaço em disco
free -h       # Memória
nload         # Tráfego de rede
iotop         # I/O de disco

# Conectividade
ping google.com
dig meusite.com
traceroute meusite.com
```

## 🚨 Solução de Problemas

### Nginx
```bash
# Testar configuração
sudo nginx -t

# Recarregar configuração
sudo systemctl reload nginx

# Reiniciar Nginx
sudo systemctl restart nginx

# Ver logs de erro
sudo journalctl -u nginx
```

### Painel Não Acessa
```bash
# Verificar se Node.js está rodando
sudo lsof -i :8080

# Verificar logs
pm2 logs server-panel

# Reinstalar dependências
cd panel && npm install

# Reiniciar painel
pm2 restart server-panel
```

### SSL Não Funciona
```bash
# Verificar DNS
dig meusite.com

# Testar certificado
sudo certbot certificates

# Renovar manualmente
sudo certbot renew --dry-run
```

## 📞 Comandos de Diagnóstico

### Informações do Sistema
```bash
# Versão do sistema
cat /etc/os-release

# Hardware
lscpu
free -h
df -h
lsblk

# Rede
ip addr show
ss -tuln
```

### Logs Importantes
```bash
# Logs gerais do sistema
sudo journalctl -f

# Logs específicos
sudo journalctl -u nginx
sudo journalctl -u mysql
sudo journalctl -u ssh
```

---

## ✅ Checklist Pós-Instalação

Execute os comandos abaixo para verificar se tudo está funcionando:

```bash
# 1. Verificar serviços
sudo systemctl is-active nginx mysql postgresql redis php8.1-fpm

# 2. Testar Nginx
curl http://localhost

# 3. Testar painel
curl http://localhost:8080

# 4. Verificar logs
sudo tail -n 20 /var/log/nginx/access.log

# 5. Testar conectividade
ping -c 3 google.com
```

**Se todos os comandos executarem sem erro, sua instalação foi bem-sucedida! 🎉**

---

## 🆘 Comandos de Emergência

### Parar Todos os Serviços
```bash
sudo systemctl stop nginx mysql postgresql redis php8.1-fpm
```

### Reiniciar Todos os Serviços
```bash
sudo systemctl restart nginx mysql postgresql redis php8.1-fpm
```

### Backup de Emergência
```bash
sudo ./scripts/backup.sh full
```

### Restaurar Sistema
```bash
# Restaurar configuração do Nginx
sudo cp /.lixeira/nginx-sites/* /etc/nginx/sites-available/
sudo systemctl reload nginx
```

**Mantenha sempre este arquivo acessível para consulta rápida! 📖**
