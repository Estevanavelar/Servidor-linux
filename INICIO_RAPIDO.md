# ⚡ Início Rápido - Servidor Linux Profissional

## 🚀 **Instalação em 1 Comando (RECOMENDADO)**

### Para Servidor Ubuntu/Debian:
```bash
# 1. Login como root
sudo su -

# 2. Executar instalação automática (substitua pelos seus dados)
bash <(wget -qO- https://raw.githubusercontent.com/Estevanavelar/servidor-linux/main/install-root.sh) panel.seudominio.com admin@seudominio.com
```

**⏱️ Tempo:** 5-10 minutos  
**📍 Local:** `/root/servidor-linux/`  
**🌐 URL:** `https://panel.seudominio.com`  
**👤 Login:** `admin` / `1583`  

---

## ✅ **O que Será Instalado Automaticamente**

### 🔧 **Sistema Base**
- ✅ **Node.js 18** + npm + PM2
- ✅ **Nginx** com SSL automático
- ✅ **MySQL** + PHP 8.1-FPM
- ✅ **Redis** + PostgreSQL  
- ✅ **Certbot** para SSL gratuito

### 🎛️ **Painel Profissional**
- ✅ **Interface moderna** Tailwind CSS
- ✅ **Dashboard** com gráficos tempo real
- ✅ **Gestão de sites** visual
- ✅ **SSL automático** para domínios
- ✅ **Gerenciador de arquivos** web
- ✅ **Monitoramento** de sistema

### 🔄 **Automação Completa**
- ✅ **Auto-start** no boot (4 camadas)
- ✅ **Monitoramento** a cada 5 minutos  
- ✅ **Backup diário** automático
- ✅ **SSL renewal** automático
- ✅ **Recovery** automático de falhas

---

## 📋 **Pós-Instalação (5 minutos)**

### 1. **Verificar Instalação**
```bash
# Ver status geral
pm2 status

# Testar conectividade
curl https://panel.seudominio.com/health

# Executar teste completo
/root/servidor-linux/scripts/test-boot.sh
```

### 2. **Acessar o Painel**
- 🌐 **URL:** `https://panel.seudominio.com`
- 👤 **Usuário:** `admin`
- 🔐 **Senha:** `1583`

### 3. **Primeiras Configurações**
- [ ] **Mudar senha** de acesso
- [ ] **Configurar email** para alertas  
- [ ] **Criar primeiro site** de teste
- [ ] **Testar SSL** automático
- [ ] **Verificar backup** funcionando

### 4. **Teste de Inicialização**
```bash
# Reiniciar servidor para testar auto-start
sudo reboot

# Aguardar 3-5 minutos, depois verificar:
# https://panel.seudominio.com deve estar funcionando
```

---

## 🎯 **Usar o Painel**

### **Dashboard Principal**
- 📊 **Gráficos** de CPU, memória em tempo real
- 🔍 **Status** de todos os serviços
- 📈 **Estatísticas** de sites e SSL

### **Gerenciar Sites**
1. **Novo Site** → Clique "Novo Site"
2. **Digite domínio** → `cliente.com`
3. **Marcar PHP** se necessário
4. **Marcar SSL** para certificado automático
5. **Criar** → Site funcionando em segundos

### **Certificados SSL**
1. **Auto-criados** quando criar site com SSL marcado
2. **Manual** → "Obter SSL" → Domínio + Email
3. **Renovação** → Automática via cron

### **Monitoramento**
- **Tempo real** via WebSocket
- **Alertas** automáticos por email
- **Logs** centralizados de todos serviços

---

## 🚨 **Se Algo Der Errado**

### **Painel não acessa**
```bash
# 1. Verificar PM2
pm2 status
pm2 restart server-panel

# 2. Verificar Nginx  
sudo systemctl status nginx
sudo nginx -t

# 3. Ver logs
pm2 logs server-panel
```

### **SSL não funciona**
```bash
# 1. Verificar DNS
dig panel.seudominio.com

# 2. Forçar SSL
sudo certbot --nginx -d panel.seudominio.com

# 3. Ver logs SSL
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### **Servidor não inicia após reboot**
```bash
# 1. Aguardar 5 minutos (serviços demoram)

# 2. Executar teste
/root/servidor-linux/scripts/test-boot.sh

# 3. Forçar start
/root/servidor-linux/scripts/ensure-panel-running.sh
```

---

## 📚 **Documentação Completa**

### **Guias Principais:**
- 📖 **[RESUMO_PROJETO.md](docs/RESUMO_PROJETO.md)** - Visão executiva completa
- 🔥 **[INSTALACAO_ROOT.md](docs/INSTALACAO_ROOT.md)** - Instalação detalhada
- 🎛️ **[PAINEL_PROFISSIONAL.md](docs/PAINEL_PROFISSIONAL.md)** - Guia do painel
- 🔧 **[SOLUCAO_SSH.md](docs/SOLUCAO_SSH.md)** - Problemas de conectividade
- 📚 **[INDICE.md](docs/INDICE.md)** - Navegação completa

### **Comandos Úteis:**
```bash
# Status do sistema
pm2 status && systemctl status nginx mysql php8.1-fpm

# Logs importantes  
pm2 logs server-panel
tail -f /var/log/nginx/panel-*-access.log

# Testes automáticos
/root/servidor-linux/scripts/test-boot.sh
/root/servidor-linux/scripts/ensure-panel-running.sh

# Atualização
/usr/local/bin/update-panel
```

---

## 🏆 **RESULTADO FINAL**

### ✅ **Você Agora Possui:**

- 🎛️ **Painel moderno** como cPanel mas personalizado
- 🌐 **Acesso seguro** HTTPS de qualquer lugar
- 🔄 **Sistema 100% confiável** que sempre funciona
- 📊 **Monitoramento profissional** em tempo real  
- 🔒 **SSL automático** para todos os sites
- 💾 **Backup automático** diário
- 📱 **Interface responsiva** para mobile
- 🤖 **Automação completa** zero-maintenance

### 🎯 **Pronto Para:**
- **Hospedagem comercial** de clientes
- **Sites WordPress** com SSL automático
- **Aplicações Node.js/PHP** modernas
- **Múltiplos domínios** gerenciados
- **Scaling** para centenas de sites

---

**🔥 TRANSFORMAÇÃO COMPLETA: De script básico para solução profissional de hospedagem comercial!**

**💎 Economize $180-540/ano em licenças cPanel + tenha controle total!**

**🌟 Comece agora: Execute 1 comando e tenha um sistema profissional funcionando!**
