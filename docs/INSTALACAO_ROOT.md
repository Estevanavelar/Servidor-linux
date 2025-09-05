# 🚀 Instalação na Pasta Root - Guia Simplificado

## 📋 Instalação Automática (Recomendado)

### Comando Único de Instalação
Execute este comando **único** no seu servidor Ubuntu como **root**:

```bash
# Fazer login como root
sudo su -

# Executar instalação completa
bash <(curl -s https://raw.githubusercontent.com/seu-usuario/servidor-linux/main/install-root.sh) panel.seudominio.com admin@seudominio.com
```

**Substitua:**
- `panel.seudominio.com` → seu domínio real
- `admin@seudominio.com` → seu email real

## 🔧 Instalação Manual

### 1. Preparar o Sistema
```bash
# Login como root
sudo su -

# Navegar para pasta root
cd /root

# Atualizar sistema
apt update && apt upgrade -y

# Instalar dependências
apt install -y git curl wget unzip build-essential
```

### 2. Instalar Node.js 18
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g pm2
```

### 3. Instalar Servidor Web
```bash
# Nginx, MySQL, PHP
apt install -y nginx mysql-server php8.1-fpm php8.1-mysql
apt install -y redis-server certbot python3-certbot-nginx

# Iniciar serviços
systemctl start nginx mysql php8.1-fpm redis-server
systemctl enable nginx mysql php8.1-fpm redis-server
```

### 4. Clonar Projeto na Root
```bash
# Na pasta /root
cd /root

# Clonar projeto
git clone https://github.com/Estevanavelar/servidor-linux.git

# Navegar para o projeto
cd servidor-linux
```

### 5. Configurar Painel
```bash
# Dar permissões
chmod +x scripts/*.sh

# Instalar dependências
cd panel
npm install

# Configurar domínio (substitua pelos seus dados)
cd /root/servidor-linux
./scripts/setup-panel-domain.sh panel.seudominio.com admin@seudominio.com
```

## 📁 Estrutura de Arquivos

### Localização no Sistema
```
/root/
├── servidor-linux/           # ← Projeto principal
│   ├── panel/                # ← Painel web
│   │   ├── server-new.js     # ← Servidor Node.js
│   │   ├── public/           # ← Interface web
│   │   ├── logs/             # ← Logs do painel
│   │   └── .env              # ← Configurações
│   ├── scripts/              # ← Scripts de automação
│   │   ├── setup-panel-domain.sh
│   │   ├── ensure-panel-running.sh
│   │   └── test-boot.sh
│   └── docs/                 # ← Documentação
```

### Arquivos de Sistema
```
/etc/nginx/sites-available/panel-seudominio.com  # Config Nginx
/etc/systemd/system/server-panel-backup.service  # Serviço backup
/var/log/nginx/panel-*-access.log               # Logs Nginx
/var/log/panel-monitor.log                      # Logs monitoramento
/usr/local/bin/update-panel                     # Script atualização
```

## 🔄 Inicialização Automática

### Serviços Configurados
Todos estes serviços **iniciam automaticamente** no boot:

```bash
# Verificar status dos serviços
systemctl is-enabled nginx              # ✅ enabled
systemctl is-enabled mysql              # ✅ enabled
systemctl is-enabled php8.1-fpm         # ✅ enabled
systemctl is-enabled redis-server       # ✅ enabled
systemctl is-enabled server-panel-backup # ✅ enabled

# PM2 também está configurado para auto-start
pm2 startup  # ✅ configurado
pm2 list     # server-panel deve estar listado
```

### Monitoramento Automático
```bash
# Crontab configurado automaticamente:
crontab -l

# Deve mostrar:
# */5 * * * * /root/servidor-linux/scripts/ensure-panel-running.sh
# @reboot sleep 120 && /root/servidor-linux/scripts/ensure-panel-running.sh
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔍 Comandos de Verificação

### Status do Painel
```bash
# Status PM2
pm2 status

# Logs em tempo real
pm2 logs server-panel

# Testar conectividade local
curl http://localhost:3000/health

# Testar via domínio
curl https://panel.seudominio.com/health
```

### Teste Completo dos Serviços
```bash
# Executar teste completo
/root/servidor-linux/scripts/test-boot.sh

# Verificar monitoramento
tail -f /var/log/panel-monitor.log

# Forçar verificação manual
/root/servidor-linux/scripts/ensure-panel-running.sh
```

## 🌐 Acesso ao Painel

### Dados de Acesso
- **URL:** https://panel.seudominio.com
- **Usuário:** admin
- **Senha:** 1583 *(configurada automaticamente)*

### Primeira Configuração
1. Acesse o painel via browser
2. Faça login com admin/1583
3. **Mude a senha imediatamente** 
4. Configure email para alertas
5. Teste criação de um site

## 🔧 Comandos de Manutenção

### Gerenciar Painel
```bash
# Reiniciar painel
pm2 restart server-panel

# Parar painel
pm2 stop server-panel

# Iniciar painel
pm2 start server-panel

# Ver logs detalhados
pm2 logs server-panel --lines 100

# Monitoramento visual
pm2 monit
```

### Atualizar Painel
```bash
# Script automático de atualização
/usr/local/bin/update-panel

# Ou manualmente:
cd /root/servidor-linux
git pull origin main
cd panel
npm install
pm2 restart server-panel
systemctl reload nginx
```

### Gerenciar Nginx
```bash
# Status do Nginx
systemctl status nginx

# Testar configuração
nginx -t

# Recarregar configuração
systemctl reload nginx

# Ver logs
tail -f /var/log/nginx/panel-*-access.log
```

## 🔒 Configurações de Segurança

### Arquivo .env
```bash
# Editar configurações
nano /root/servidor-linux/panel/.env

# Principais configurações:
NODE_ENV=production
SECRET_KEY=sua-chave-secreta
ADMIN_USER=admin
ADMIN_PASSWORD_HASH=hash-da-senha
PANEL_DOMAIN=panel.seudominio.com
```

### Firewall
```bash
# Verificar firewall
ufw status

# Deve mostrar:
# 22/tcp     ALLOW       # SSH
# 80,443/tcp ALLOW       # HTTP/HTTPS
```

## 🚨 Solução de Problemas

### Painel não acessa
```bash
# 1. Verificar se PM2 está rodando
pm2 status

# 2. Verificar logs
pm2 logs server-panel

# 3. Verificar porta 3000
curl http://localhost:3000/health

# 4. Reiniciar painel
pm2 restart server-panel

# 5. Verificar Nginx
nginx -t
systemctl status nginx
```

### SSL não funciona
```bash
# 1. Verificar certificado
certbot certificates

# 2. Renovar manualmente
certbot --nginx -d panel.seudominio.com

# 3. Verificar DNS
dig panel.seudominio.com

# 4. Testar conectividade
curl -I https://panel.seudominio.com
```

### Servidor não inicia após reboot
```bash
# 1. Aguardar 5 minutos (serviços demoram a iniciar)

# 2. Executar teste completo
/root/servidor-linux/scripts/test-boot.sh

# 3. Ver logs do sistema
journalctl -f

# 4. Verificar PM2
pm2 resurrect

# 5. Forçar inicialização
/root/servidor-linux/scripts/ensure-panel-running.sh
```

## ✅ Checklist Pós-Instalação

- [ ] Painel acessa via https://panel.seudominio.com
- [ ] Login funciona (admin/1583)
- [ ] SSL está funcionando (cadeado verde)
- [ ] PM2 mostra server-panel online
- [ ] Todos os serviços estão enabled
- [ ] Cron está configurado
- [ ] Teste de reboot realizado

## 🎯 Próximos Passos

1. **Mudar senha padrão** no painel
2. **Criar primeiro site** de teste
3. **Configurar backup external** (opcional)
4. **Configurar monitoramento** avançado
5. **Documentar acessos** para equipe

---

## 🏆 Resultado Final

Com essa configuração você terá:

✅ **Painel moderno e profissional**  
✅ **Acesso seguro de qualquer lugar**  
✅ **Inicialização automática 100% confiável**  
✅ **Monitoramento a cada 5 minutos**  
✅ **SSL automático renovável**  
✅ **Backup automático diário**  
✅ **Interface responsiva para mobile**  
✅ **Pronto para hospedagem comercial**  

**🔥 Seu servidor na pasta root está pronto para competir com cPanel!**
