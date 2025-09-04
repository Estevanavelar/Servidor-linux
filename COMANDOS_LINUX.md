# 🐧 Comandos para Executar no Servidor Ubuntu

> **Importante:** Este projeto foi desenvolvido no Windows, mas é destinado para execução em servidores Ubuntu. Os comandos abaixo devem ser executados no seu servidor Ubuntu.

## 🚀 Instalação Completa no Ubuntu

### 1. Preparar o Sistema Ubuntu
```bash
# Atualizar sistema Ubuntu
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install git curl wget unzip -y
```

### 2. Baixar o Projeto
```bash
# Clone via Git
git clone https://github.com/Estevanavelar/servidor-linux.git
cd servidor-linux
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
# EXECUTAR COMO ROOT/SUDO (Ubuntu)
sudo ./scripts/install-server.sh
```

**⏱️ Aguarde 15-30 minutos para instalação completa no Ubuntu**

> **💡 Dica Ubuntu:** Durante a instalação, você pode acompanhar o progresso em outro terminal:
> ```bash
> sudo tail -f /var/log/syslog
> ```

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

## 🔍 Comandos de Verificação no Ubuntu

### Status dos Serviços
```bash
# Verificar todos os serviços principais
sudo systemctl status nginx mysql postgresql redis php8.1-fpm

# Verificar portas abertas
sudo ss -tuln | grep -E ':(22|80|443|3306|5432|6379|8080)'

# Verificar processos em tempo real
htop

# Verificar status resumido de todos os serviços
sudo systemctl is-active nginx mysql postgresql redis php8.1-fpm
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
# Conectar via SSH (IPv4)
ssh usuario@192.168.1.100

# Conectar via SSH (IPv6) - Colchetes são obrigatórios
ssh usuario@[2804:3dc8:211:2dea:c559:d519:faa9:1ed0]

# Conectar com porta específica
ssh -p 2222 usuario@servidor.com

# Conectar com chave SSH
ssh -i ~/.ssh/chave_privada usuario@servidor.com

# Conectar com timeout personalizado
ssh -o ConnectTimeout=10 usuario@servidor.com

# Conectar em modo verbose para debug
ssh -v usuario@servidor.com

# Editar configuração SSH
sudo nano /etc/ssh/sshd_config

# Reiniciar SSH
sudo systemctl restart ssh

# Verificar conexões SSH ativas
who
w

# Verificar tentativas de login SSH
sudo tail -f /var/log/auth.log
```

### Diagnóstico de Problemas SSH IPv6
```bash
# Windows - Verificar conectividade IPv6
ping -6 ipv6.google.com

# Windows - Verificar configuração IPv6 local
ipconfig /all | findstr IPv6

# Windows - Testar conectividade básica
ping -6 [endereço-ipv6]

# Windows - Verificar se IPv6 está habilitado
netsh interface ipv6 show config

# Linux - Verificar conectividade IPv6
ping6 ipv6.google.com

# Linux - Verificar endereços IPv6
ip -6 addr show

# Fazer reverse DNS do IPv6
nslookup [endereço-ipv6]

# Testar conexão TCP específica
telnet [endereço-ipv6] 22
```

### Problemas Comuns IPv6
```bash
# Problema: "falha na transmissão" ou "Unknown error"
# Causa: IPv6 não configurado globalmente
# Solução: Verificar com ISP ou usar túnel IPv6

# Problema: "Connection refused"
# Causa: SSH não está rodando ou porta bloqueada
# Solução: Verificar serviço SSH no servidor

# Problema: "Network unreachable"
# Causa: Roteamento IPv6 incorreto
# Solução: Verificar gateway IPv6
```

### Firewall Ubuntu (UFW)
```bash
# Verificar status do firewall
sudo ufw status

# Ativar firewall (se não estiver ativo)
sudo ufw enable

# Permitir portas essenciais
sudo ufw allow ssh        # SSH (porta 22)
sudo ufw allow 80         # HTTP
sudo ufw allow 443        # HTTPS
sudo ufw allow 8080       # Painel de controle

# Verificar regras ativas
sudo ufw status numbered

# Exemplo: remover regra específica
# sudo ufw delete [número]
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
# Atualizar sistema Ubuntu
sudo apt update && sudo apt upgrade -y

# Atualizar Node.js packages globais
sudo npm update -g

# Limpar sistema Ubuntu
sudo apt autoremove && sudo apt autoclean
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

## ✅ Checklist Pós-Instalação Ubuntu

Execute os comandos abaixo para verificar se tudo está funcionando:

```bash
# 1. Verificar serviços principais
sudo systemctl is-active nginx mysql postgresql redis php8.1-fpm

# 2. Testar Nginx
curl http://localhost

# 3. Testar painel de controle
curl http://localhost:8080

# 4. Verificar logs do Nginx
sudo tail -n 20 /var/log/nginx/access.log

# 5. Testar conectividade
ping -c 3 google.com

# 6. Verificar versões instaladas
nginx -v && node --version && php --version

# 7. Verificar espaço em disco
df -h

# 8. Verificar memória disponível
free -h
```

**Se todos os comandos executarem sem erro, sua instalação Ubuntu foi bem-sucedida! 🎉**

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

---

## 🐧 Comandos Específicos do Ubuntu

### Gerenciamento de Pacotes
```bash
# Buscar pacote
apt search nome-do-pacote

# Informações sobre pacote
apt show nome-do-pacote

# Listar pacotes instalados
apt list --installed

# Limpar cache de pacotes
sudo apt autoclean && sudo apt autoremove
```

### Informações do Sistema Ubuntu
```bash
# Versão do Ubuntu
lsb_release -a

# Informações detalhadas
sudo lshw -short

# Verificar se é Ubuntu Server ou Desktop
dpkg -l ubuntu-desktop ubuntu-server-*
```

### Logs Específicos do Ubuntu
```bash
# Logs do sistema Ubuntu
sudo journalctl -f

# Logs de inicialização
sudo journalctl -b

# Logs de um serviço específico
sudo journalctl -u nginx -f
```

### Performance no Ubuntu
```bash
# Processos que mais consomem CPU
top -o %CPU

# Processos que mais consomem memória  
top -o %MEM

# Informações de rede
sudo netstat -tuln
```

**Mantenha sempre este arquivo acessível para consulta rápida no seu servidor Ubuntu! 📖**
