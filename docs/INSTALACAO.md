# 🚀 Guia de Instalação - Servidor Linux

## 📋 Pré-requisitos

### Sistema Operacional Suportado
- Ubuntu 20.04+ (Recomendado)
- Debian 10+
- CentOS 8+
- RHEL 8+

### Recursos Mínimos
- **CPU:** 2 cores
- **RAM:** 4GB (8GB recomendado)
- **Disco:** 50GB livres
- **Rede:** Conexão estável com internet

### Acesso
- Acesso root ou sudo ao servidor
- Porta 22 (SSH) liberada
- Portas 80 e 443 liberadas para web

## 🔧 Instalação Automática

### 1. Download do Sistema

```bash
# Opção 1: Via Git
git clone https://github.com/seu-usuario/servidor-linux.git
cd servidor-linux

# Opção 2: Download direto
wget https://github.com/seu-usuario/servidor-linux/archive/main.zip
unzip main.zip
cd servidor-linux-main
```

### 2. Preparar Scripts

```bash
# Dar permissão de execução
chmod +x scripts/*.sh

# Verificar integridade
ls -la scripts/
```

### 3. Executar Instalação

```bash
# IMPORTANTE: Execute como root/sudo
sudo ./scripts/install-server.sh
```

**⏱️ Tempo de instalação:** 15-30 minutos

### 4. Iniciar Painel

```bash
# Aguardar instalação concluir, depois:
./scripts/start-panel.sh
```

## 📺 Durante a Instalação

### O que você verá:

```
🚀 Iniciando instalação completa do servidor...
Sistema detectado: Ubuntu 20.04 (ubuntu 20.04)
Atualizando sistema...
Instalando Nginx...
Instalando Node.js e TypeScript...
Instalando PHP 8.1...
Instalando Python 3.9+ e pip...
Instalando bancos de dados...
Configurando SSH e segurança...
Instalando ferramentas adicionais...
Configurando firewall...
✅ Instalação completa finalizada com sucesso!
```

### Serviços Instalados:
- ✅ Nginx (Servidor web)
- ✅ Node.js + TypeScript
- ✅ PHP 8.1 + extensões
- ✅ Python 3 + pip
- ✅ MySQL + PostgreSQL + SQLite
- ✅ Redis (Cache)
- ✅ SSH + Fail2Ban
- ✅ Firewall configurado
- ✅ Certbot (SSL)

## 🎛️ Acessar Painel

### URL de Acesso
```
http://SEU-IP-SERVIDOR:8080
```

### Credenciais Padrão
- **Usuário:** `admin`
- **Senha:** `admin123`

> ⚠️ **IMPORTANTE:** Altere a senha padrão imediatamente!

## ✅ Verificar Instalação

### Testar Serviços

```bash
# Verificar status dos serviços
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status postgresql
sudo systemctl status redis
sudo systemctl status php8.1-fpm

# Verificar portas abertas
sudo ss -tuln | grep -E ':(22|80|443|3306|5432|6379|8080)'

# Testar Nginx
curl http://localhost

# Testar painel
curl http://localhost:8080
```

### Verificar Versões

```bash
# Nginx
nginx -v

# Node.js
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

## 🔒 Pós-Instalação (Segurança)

### 1. Alterar Senha do Painel

Editar arquivo do servidor:
```bash
sudo nano panel/server.js
```

Localizar e alterar:
```javascript
const defaultPass = 'SUA_NOVA_SENHA_FORTE';
```

### 2. Configurar Chave Secreta

```bash
# Gerar chave única
openssl rand -hex 32

# Definir variável de ambiente
export SECRET_KEY="sua_chave_gerada_aqui"
```

### 3. Configurar MySQL

```bash
# Executar configuração segura
sudo mysql_secure_installation
```

Responder:
- Remove anonymous users? **Y**
- Disallow root login remotely? **Y**
- Remove test database? **Y**
- Reload privilege tables? **Y**

### 4. Configurar PostgreSQL

```bash
# Definir senha do usuário postgres
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'sua_senha_forte';"
```

## 🌐 Primeiro Site

### Criar Site de Teste

```bash
# Criar site básico
sudo ./scripts/domain-ssl.sh create-site meusite.com

# Site com PHP
sudo ./scripts/domain-ssl.sh create-site php.meusite.com /var/www/php yes
```

### Configurar DNS

Aponte seu domínio para o IP do servidor:
```
A    meusite.com          -> SEU_IP_SERVIDOR
A    www.meusite.com      -> SEU_IP_SERVIDOR
A    php.meusite.com      -> SEU_IP_SERVIDOR
```

### Instalar SSL

```bash
# Aguardar DNS propagar (5-30 minutos), depois:
sudo ./scripts/domain-ssl.sh install-ssl meusite.com admin@meusite.com
```

## 🚨 Solução de Problemas

### Erro: "Command not found"

```bash
# Verificar se tem permissão
ls -la scripts/install-server.sh

# Dar permissão se necessário
chmod +x scripts/install-server.sh
```

### Erro: "Not root"

```bash
# Executar com sudo
sudo ./scripts/install-server.sh
```

### Erro: "Package not found"

```bash
# Atualizar repositórios
sudo apt update  # Ubuntu/Debian
sudo yum update  # CentOS/RHEL
```

### Erro: "Port already in use"

```bash
# Verificar processo usando a porta
sudo lsof -i :80
sudo lsof -i :8080

# Parar processo se necessário
sudo systemctl stop nginx
sudo pkill -f "node.*server.js"
```

### Nginx não inicia

```bash
# Verificar configuração
sudo nginx -t

# Ver logs de erro
sudo journalctl -u nginx

# Verificar sintaxe dos sites
sudo nginx -T
```

### Painel não acessa

```bash
# Verificar se Node.js está instalado
node --version

# Verificar dependências
cd panel && npm list

# Instalar dependências se necessário
npm install

# Verificar logs
sudo journalctl -f
```

## 📊 Monitoramento

### Durante a Instalação

Acompanhar logs em tempo real:
```bash
# Terminal 1: Executar instalação
sudo ./scripts/install-server.sh

# Terminal 2: Acompanhar logs
sudo tail -f /var/log/syslog
```

### Após Instalação

```bash
# Status geral
sudo systemctl list-units --type=service --state=running

# Uso de recursos
htop
df -h
free -h
```

## 🔄 Desinstalação

Se precisar remover o sistema:

```bash
# Parar serviços
sudo systemctl stop nginx mysql postgresql redis php8.1-fpm

# Remover packages (Ubuntu/Debian)
sudo apt remove --purge nginx mysql-server postgresql redis-server php8.1*

# Limpar configurações
sudo rm -rf /etc/nginx
sudo rm -rf /var/www
sudo rm -rf /etc/mysql
sudo rm -rf /var/lib/postgresql

# CUIDADO: Isso remove TODOS os dados!
```

## 📞 Suporte

### Logs Importantes

```bash
# Logs de instalação
sudo journalctl -u install-server

# Logs do sistema
sudo tail -f /var/log/syslog

# Logs específicos dos serviços
sudo journalctl -u nginx
sudo journalctl -u mysql
```

### Informações do Sistema

```bash
# Versão do OS
cat /etc/os-release

# Recursos disponíveis
free -h
df -h
lscpu
```

## ✅ Checklist Final

Após instalação, verificar:

- [ ] Nginx respondendo na porta 80
- [ ] Painel acessível na porta 8080
- [ ] MySQL funcionando
- [ ] PostgreSQL funcionando
- [ ] Redis funcionando
- [ ] PHP-FPM ativo
- [ ] SSH configurado
- [ ] Firewall ativo
- [ ] Fail2Ban ativo
- [ ] Página de teste do Nginx aparecendo

**Se todos os itens estão OK, sua instalação foi bem-sucedida! 🎉**

---

## 🚀 Próximos Passos

1. **Acessar painel:** `http://SEU-IP:8080`
2. **Alterar senha padrão**
3. **Criar primeiro site**
4. **Configurar domínio**
5. **Instalar SSL**
6. **Fazer backup das configurações**

**Bem-vindo ao seu novo servidor Linux! 🌟**
