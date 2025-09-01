# 📚 Guia Completo - Sistema de Configuração de Servidor Linux

## 🎯 Visão Geral

Este sistema oferece uma solução completa para configuração e gerenciamento de servidores Linux, incluindo:

- **Instalação automatizada** de todas as dependências necessárias
- **Painel de controle web** moderno e intuitivo
- **Gerenciamento de domínios e SSL** simplificado
- **Monitoramento em tempo real** do sistema
- **Interface visual** para administração

## 🚀 Instalação Rápida

### 1. Preparar o Sistema

```bash
# Baixar o projeto
git clone https://github.com/Estevanavelar/servidor-linux.git
cd servidor-linux

# Dar permissão de execução
chmod +x scripts/*.sh
```

### 2. Executar Instalação Completa

```bash
# Instalar TUDO (execute como root)
sudo ./scripts/install-server.sh
```

⏱️ **Tempo estimado:** 15-30 minutos (dependendo da conexão)

### 3. Iniciar Painel de Controle

```bash
# Iniciar painel web
./scripts/start-panel.sh
```

🌐 **Acesso:** `http://SEU-IP:8080`  
👤 **Login:** `admin` / `admin123`

## 📋 O Que é Instalado

### 🌐 Servidor Web
- **Nginx** - Servidor web de alta performance
- Configurações otimizadas para produção
- Gzip, cache, headers de segurança

### 💻 Linguagens de Programação
- **Node.js 18** + npm + yarn
- **TypeScript** + ts-node
- **PHP 8.1** + PHP-FPM + extensões
- **Python 3** + pip + virtualenv

### 🗄️ Bancos de Dados
- **MySQL** - Banco relacional popular
- **PostgreSQL** - Banco robusto para aplicações
- **SQLite** - Banco leve para projetos menores
- **Redis** - Cache em memória

### 🔒 Segurança
- **SSH** configurado com melhores práticas
- **Fail2Ban** para proteção contra ataques
- **Firewall** (UFW/Firewalld) configurado
- **Certbot** para SSL/TLS automático

### 🛠️ Ferramentas
- **Git** - Controle de versão
- **PM2** - Gerenciador de processos Node.js
- **Certbot** - Geração automática de SSL
- **htop, nload, iotop** - Monitoramento

## 🎛️ Painel de Controle

### 📊 Visão Geral
- Status do sistema em tempo real
- Uso de CPU, memória e disco
- Status de todos os serviços
- Uptime do servidor

### 🌐 Gerenciamento de Sites
- Criar novos sites com poucos cliques
- Habilitar/desabilitar sites
- Configuração automática do Nginx
- Suporte a PHP opcional

### 🔒 Certificados SSL
- Obtenção automática via Let's Encrypt
- Renovação automática configurada
- Monitoramento de validade

### 📁 Gerenciador de Arquivos
- Interface web para navegação
- Upload de arquivos
- Criação de pastas
- Edição básica de arquivos

### 📊 Logs em Tempo Real
- Logs do Nginx
- Logs do sistema
- WebSocket para atualização em tempo real

## 🌐 Gerenciamento de Domínios

### Criar Novo Site

```bash
# Site básico HTML
sudo ./scripts/domain-ssl.sh create-site meusite.com

# Site com PHP habilitado
sudo ./scripts/domain-ssl.sh create-site meusite.com /var/www/meusite yes

# Site em diretório personalizado
sudo ./scripts/domain-ssl.sh create-site meusite.com /opt/websites/meusite
```

### Instalar SSL

```bash
# Obter certificado SSL
sudo ./scripts/domain-ssl.sh install-ssl meusite.com admin@meusite.com
```

### Listar Sites

```bash
# Ver todos os sites configurados
./scripts/domain-ssl.sh list-sites
```

### Remover Site

```bash
# Remover site (move para .lixeira)
sudo ./scripts/domain-ssl.sh remove-site meusite.com
```

## 🔧 Configurações Avançadas

### Nginx Personalizado

Editar configuração global:
```bash
sudo nano /etc/nginx/nginx.conf
```

Configuração específica do site:
```bash
sudo nano /etc/nginx/sites-available/meusite.com
```

### PHP-FPM

Configurar pool personalizado:
```bash
sudo nano /etc/php/8.1/fpm/pool.d/www.conf
```

Restart PHP-FPM:
```bash
sudo systemctl restart php8.1-fpm
```

### MySQL

Configuração segura:
```bash
sudo mysql_secure_installation
```

Acessar console:
```bash
sudo mysql -u root -p
```

### PostgreSQL

Acessar console:
```bash
sudo -u postgres psql
```

Criar usuário e banco:
```sql
CREATE USER meuusuario WITH PASSWORD 'minhasenha';
CREATE DATABASE meubanco OWNER meuusuario;
```

## 🔒 Segurança

### SSH Hardening

O script já configura SSH com:
- Desabilita root login
- Configura chaves públicas
- Rate limiting
- Configurações seguras

### Firewall

Abrir porta personalizada:
```bash
# Ubuntu/Debian
sudo ufw allow 3000

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### Fail2Ban

Ver status:
```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

Desbanir IP:
```bash
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

## 📊 Monitoramento

### Logs Importantes

```bash
# Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# MySQL
tail -f /var/log/mysql/error.log

# Sistema
tail -f /var/log/syslog
```

### Comandos Úteis

```bash
# Status dos serviços
sudo systemctl status nginx mysql postgresql redis php8.1-fpm

# Uso de recursos
htop
nload
iotop

# Espaço em disco
df -h

# Processos de rede
ss -tuln
```

## 🚨 Solução de Problemas

### Nginx Não Inicia

```bash
# Verificar configuração
sudo nginx -t

# Ver logs de erro
sudo journalctl -u nginx

# Verificar porta em uso
sudo lsof -i :80
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

### Painel Não Acessa

```bash
# Verificar se está rodando
sudo lsof -i :8080

# Ver logs
sudo journalctl -u server-panel

# Restart painel
sudo pm2 restart server-panel
```

## 🔧 Manutenção

### Backup Automático

O sistema já configura backup automático:
- Sites: `/backups/sites-YYYY-MM-DD.tar.gz`
- Configurações: `/backups/configs-YYYY-MM-DD.tar.gz`

### Atualizações

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# Atualizar Node.js
sudo npm install -g npm@latest

# Atualizar PHP
sudo apt update && sudo apt upgrade php8.1*
```

### Limpeza

```bash
# Limpar logs antigos
sudo find /var/log -name "*.log" -type f -mtime +30 -delete

# Limpar cache
sudo apt autoremove && sudo apt autoclean

# Limpar .lixeira
sudo rm -rf /.lixeira/*
```

## 🌟 Recursos Avançados

### Configurar Multi-Sites

```bash
# Site 1
sudo ./scripts/domain-ssl.sh create-site site1.com

# Site 2
sudo ./scripts/domain-ssl.sh create-site site2.com

# Site 3 com PHP
sudo ./scripts/domain-ssl.sh create-site site3.com /var/www/site3 yes
```

### Proxy Reverso para Apps Node.js

Editar configuração do Nginx:
```nginx
location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
```

### Configurar Subdomínios

```bash
# API subdomain
sudo ./scripts/domain-ssl.sh create-site api.meusite.com

# Admin subdomain  
sudo ./scripts/domain-ssl.sh create-site admin.meusite.com
```

## 📞 Suporte e Contribuição

### Reportar Problemas

1. Verificar os logs primeiro
2. Criar issue com informações detalhadas
3. Incluir versão do sistema operacional
4. Incluir logs de erro relevantes

### Contribuir

1. Fork do repositório
2. Criar branch para feature
3. Testar em ambiente limpo
4. Submeter pull request

## 📋 Checklist de Produção

### Antes de Ir para Produção

- [ ] Alterar senha padrão do painel
- [ ] Configurar backup externo
- [ ] Testar renovação SSL
- [ ] Configurar monitoramento externo
- [ ] Documentar credenciais
- [ ] Testar restauração de backup
- [ ] Configurar alertas de sistema
- [ ] Revisar logs de segurança

### Configurações de Produção

```bash
# Alterar senha do painel (editar server.js)
sudo nano panel/server.js

# Configurar SECRET_KEY única
export SECRET_KEY="sua-chave-super-secreta-aqui"

# Configurar HTTPS para painel
# (configurar certificado SSL para IP/domínio do painel)
```

---

## 🎉 Conclusão

Com este sistema, você tem uma infraestrutura completa para hospedar múltiplos sites, aplicações e serviços em um servidor Linux. O painel de controle oferece uma interface amigável para gerenciar tudo visualmente, enquanto os scripts permitem automação e integração com outros sistemas.

**Recursos principais:**
- ✅ Instalação automatizada
- ✅ Painel de controle web
- ✅ Gerenciamento de domínios
- ✅ SSL automático
- ✅ Múltiplos bancos de dados
- ✅ Múltiplas linguagens
- ✅ Segurança configurada
- ✅ Monitoramento em tempo real
- ✅ Backup automático

**Pronto para produção!** 🚀
