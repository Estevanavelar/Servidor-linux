# 🔧 Guia Completo: Resolver Problemas de Conexão SSH

## 📋 Índice de Problemas e Soluções

1. [Conexão via Domínio/IPv4](#conexao-dominio-ipv4)
2. [Problema IPv4: "Connection timed out" (Redes diferentes)](#problema-redes-diferentes)
3. [Problema Servidor: "Connection timed out" (Servidor inacessível)](#problema-servidor-inacessivel)
4. [Configuração Cloudflare](#configuracao-cloudflare)
5. [Testes de Diagnóstico Completo](#testes-diagnostico)

---

## 🌐 Conexão via Domínio/IPv4 {#conexao-dominio-ipv4}

**✅ Método Recomendado:** Usar sempre domínio ou IPv4 público para conectar via SSH.

### 🔧 Passos para Conexão

#### 1. **Usar Domínio (RECOMENDADO)**

```bash
# Conectar via domínio
ssh usuario@meuservidor.com
ssh usuario@ssh.meuservidor.com

# Com porta personalizada
ssh -p 2222 usuario@meuservidor.com

# Com usuário específico
ssh avelar-serve@ssh.avelarcompany.dev.br
```

#### 2. **Usar IPv4 Público**

```bash
# Conectar via IP público
ssh usuario@203.0.113.10

# Com porta personalizada  
ssh -p 2222 usuario@203.0.113.10

# Forçar IPv4 apenas
ssh -4 usuario@servidor.com
```

#### 3. **Verificar DNS Antes de Conectar**

```bash
# Verificar se domínio resolve
nslookup meuservidor.com

# Verificar IP específico
nslookup ssh.avelarcompany.dev.br

# Testar conectividade básica
ping meuservidor.com
```

---

## 🚨 Problema Redes Diferentes: IPv4 Timeout {#problema-redes-diferentes}

**Erro:** `ssh: connect to host 192.168.1.3 port 22: Connection timed out`
**Causa:** Tentativa de conectar a redes locais diferentes.

**Exemplo:**
- Sua rede: `192.168.18.99` (rede 192.168.18.x)
- Servidor: `192.168.1.3` (rede 192.168.1.x)

### ✅ Soluções para Redes Diferentes

#### 1. **Verificar Endereço Correto (MAIS COMUM)**

**Problema:** Endereço fornecido pode estar incorreto.

**Passo 1:** Confirmar endereço real
```
📧 PERGUNTAR AO ADMINISTRADOR:

"O endereço SSH correto é mesmo 192.168.1.3?

Estou na rede 192.168.18.x e não consigo conectar.
O servidor tem:
- IP público? (ex: 200.100.50.25)
- Nome de domínio? (ex: servidor.empresa.com)
- Está atrás de NAT/router?"
```

**Passo 2:** Usar endereço correto fornecido

#### 2. **Conectar à Mesma Rede (PRESENCIAL)**

**Se o servidor estiver fisicamente próximo:**

**Passo 1:** Conectar à mesma rede WiFi/Ethernet
**Passo 2:** Verificar sua nova rede:
```bash
ipconfig | findstr IPv4
# Agora você deve estar em 192.168.1.x
```
**Passo 3:** Tentar SSH:
```bash
ssh avelar-serve@192.168.1.3
```

#### 3. **Configurar Roteamento (AVANÇADO)**

**⚠️ ATENÇÃO:** Só funciona se houver rota física entre redes.

**Passo 1:** Descobrir gateway da rede destino
**Passo 2:** Adicionar rota estática:
```bash
# Windows (Executar como Administrador):
route add 192.168.1.0 mask 255.255.255.0 192.168.18.1

# Verificar se funcionou:
route print | findstr 192.168.1
```
**Passo 3:** Testar conectividade:
```bash
ping 192.168.1.3
ssh avelar-serve@192.168.1.3
```

#### 4. **VPN/Túnel para Rede Remota**

**Se o servidor estiver em rede corporativa:**

**Passo 1:** Solicitar VPN corporativa
**Passo 2:** Conectar à VPN
**Passo 3:** Verificar se está na rede correta:
```bash
ipconfig | findstr IPv4
```
**Passo 4:** Tentar SSH

---

## 🚨 Problema Servidor Inacessível: Total Timeout {#problema-servidor-inacessivel}

**Erro:** Connection timeout em TODAS as portas e protocolos
**Exemplo:** ssh.avelarcompany.dev.br (160.238.151.146)

**Sinais do problema:**
- ✅ DNS resolve corretamente
- ❌ Ping falha (timeout)
- ❌ SSH falha (timeout)
- ❌ HTTP/HTTPS falha (timeout)
- ❌ Todas as portas falham

### ✅ Soluções para Servidor Inacessível

#### 1. **Verificar Status do Servidor (PRIORITÁRIO)**

**Passo 1:** Contatar administrador URGENTEMENTE
```
📧 MODELO DE MENSAGEM URGENTE:

Assunto: URGENTE - Servidor inacessível

Servidor: ssh.avelarcompany.dev.br (160.238.151.146)
Status: COMPLETAMENTE INACESSÍVEL

Testes realizados:
✅ DNS resolve corretamente para 160.238.151.146
❌ Ping timeout
❌ SSH porta 22 timeout
❌ SSH porta 2222 timeout  
❌ HTTP timeout
❌ HTTPS timeout

NECESSÁRIO VERIFICAR:
1. Servidor está ligado/funcionando?
2. Serviços SSH estão rodando?
3. Firewall está permitindo conexões externas?
4. Houve mudança recente de configuração?
5. Há proteção DDoS ativa bloqueando conexões?

Por favor, verificar status urgentemente.
```

#### 2. **Testar de Outra Localização**

**Passo 1:** Usar hotspot móvel
```bash
# Conectar celular como hotspot
# Conectar PC ao hotspot
# Tentar SSH novamente:
ssh avelar-serve@ssh.avelarcompany.dev.br
```

**Passo 2:** Testar de outra rede
- Casa de amigo/familiar
- Rede corporativa
- Café/biblioteca com WiFi

**Passo 3:** Se funcionar de outro local = problema do seu ISP

#### 3. **Verificações no Servidor (Se tiver acesso físico/console)**

```bash
# Verificar se servidor está rodando:
sudo systemctl status ssh

# Verificar se SSH está escutando:
sudo ss -tuln | grep :22
sudo netstat -tuln | grep :22

# Verificar firewall:
sudo ufw status
sudo iptables -L

# Verificar logs de tentativas:
sudo tail -f /var/log/auth.log
sudo tail -f /var/log/syslog

# Verificar conectividade externa:
curl ifconfig.me
ping google.com
```

#### 4. **Solicitar Acesso Alternativo**

**Passo 1:** Solicitar outros métodos de acesso:
```
📧 SOLICITAR ALTERNATIVAS:

"Como o SSH não está funcionando, vocês têm:

1. Console web/KVM para acesso direto?
2. VPN para conectar à rede interna?
3. Outro servidor/jump host disponível?
4. TeamViewer/AnyDesk se for Windows?
5. Acesso físico possível?"
```

---

## 🔍 Testes de Diagnóstico Completo {#testes-diagnostico}

### Windows - Comandos de Diagnóstico

#### Verificar Sua Rede
```powershell
# Verificar sua rede atual
ipconfig | findstr IPv4

# Verificar configuração IPv6
ipconfig /all | findstr IPv6

# Verificar se IPv6 está habilitado
netsh interface ipv6 show config

# Testar conectividade IPv6 global
ping -6 ipv6.google.com

# Ver dispositivos na sua rede
arp -a

# Verificar rotas de rede
route print | findstr 192.168
```

#### Testar Conectividade Específica
```powershell
# Testar conectividade básica
ping [endereço]

# Testar porta específica (PowerShell)
Test-NetConnection [endereço] -Port 22
Test-NetConnection [endereço] -Port 2222
Test-NetConnection [endereço] -Port 443

# Rastrear rota de rede
tracert [endereço]

# Resolver DNS
nslookup [endereço]
```

#### Verificar SSH Específico
```bash
# Tentar SSH com verbose (modo debug)
ssh -v usuario@meudominio.com

# Tentar SSH com timeout personalizado
ssh -o ConnectTimeout=10 usuario@meudominio.com

# Tentar SSH em porta específica
ssh -p 2222 usuario@meudominio.com

# Forçar IPv4 apenas (recomendado)
ssh -4 usuario@meudominio.com

# Tentar com IP direto para comparar
ssh usuario@203.0.113.10
```

---

## ☁️ Configuração Cloudflare {#configuracao-cloudflare}

### 🌟 **Configurar Domínio no Cloudflare para SSH**

#### 1. **Adicionar Registro A para SSH**

**No painel Cloudflare:**
```
Tipo: A
Nome: ssh (ou @)
IPv4: [IP-DO-SEU-SERVIDOR]
TTL: Auto
Proxy: 🔴 Desabilitado (cinza - DNS only)
```

**⚠️ IMPORTANTE:** Para SSH, o proxy deve estar **DESABILITADO** (nuvem cinza)

#### 2. **Verificar Configuração DNS**

```bash
# Verificar se resolve corretamente
nslookup ssh.seudominio.com

# Deve retornar o IP correto do servidor
# Exemplo: 203.0.113.10
```

#### 3. **Testar Conexão SSH**

```bash
# Conectar via domínio
ssh usuario@ssh.seudominio.com

# Ou domínio principal
ssh usuario@seudominio.com

# Com porta personalizada (se configurada)
ssh -p 2222 usuario@ssh.seudominio.com
```

### 🔧 **Configurações Recomendadas Cloudflare**

#### DNS Settings
```
# Para SSH direto
ssh.seudominio.com → A → [IP-SERVIDOR] → Proxy OFF

# Para múltiplos serviços
server.seudominio.com → A → [IP-SERVIDOR] → Proxy OFF
www.seudominio.com → A → [IP-SERVIDOR] → Proxy ON
```

#### Security Settings
- **SSL/TLS:** Full (para outros serviços web)
- **Always Use HTTPS:** ON (para web, não afeta SSH)
- **Brotli:** ON
- **Minify:** ON para CSS/JS/HTML

### 📋 **Troubleshooting Cloudflare + SSH**

#### Problema: "Connection timeout" após configurar
```bash
# 1. Verificar se proxy está desabilitado
nslookup ssh.seudominio.com
# Deve retornar IP real do servidor, não IP do Cloudflare

# 2. Verificar propagação DNS
# Aguardar 5-10 minutos após mudanças

# 3. Testar com IP direto primeiro
ssh usuario@[IP-SERVIDOR]
# Se funciona com IP mas não com domínio = problema DNS
```

#### Problema: "Name resolution failed"
```bash
# 1. Limpar cache DNS local
ipconfig /flushdns

# 2. Testar DNS público
nslookup ssh.seudominio.com 8.8.8.8

# 3. Verificar configuração no Cloudflare
```

---

## ✅ Checklist de Resolução de Problemas

### Para Conexão via Domínio/IPv4
- [ ] Verificar DNS: `nslookup meudominio.com`
- [ ] Confirmar IP público do servidor
- [ ] Verificar se domínio está configurado no Cloudflare
- [ ] Garantir que proxy Cloudflare está DESABILITADO para SSH
- [ ] Testar conectividade: `ping meudominio.com`

### Para Redes Diferentes
- [ ] Confirmar endereço correto com administrador
- [ ] Verificar se é IP público ou privado
- [ ] Conectar à mesma rede física (se possível)
- [ ] Configurar VPN corporativa (se necessário)
- [ ] Usar hotspot móvel para testar

### Para Servidor Inacessível
- [ ] Contatar administrador URGENTEMENTE
- [ ] Testar de hotspot móvel/outra rede
- [ ] Verificar se problema é do ISP ou servidor
- [ ] Solicitar acesso via console/KVM
- [ ] Pedir métodos alternativos de acesso

### Para Cloudflare
- [ ] Verificar registro A está correto
- [ ] Confirmar proxy está DESABILITADO (nuvem cinza)
- [ ] Aguardar propagação DNS (5-10 min)
- [ ] Limpar cache DNS local: `ipconfig /flushdns`
- [ ] Testar com DNS público: `nslookup dominio.com 8.8.8.8`

### Comandos de Diagnóstico
- [ ] `nslookup [servidor]` - Verificar DNS
- [ ] `ping [servidor]` - Conectividade básica
- [ ] `Test-NetConnection [servidor] -Port 22` - Teste SSH
- [ ] `tracert [servidor]` - Rastrear rota
- [ ] `ssh -v [usuario]@[servidor]` - SSH com debug

---

## 🆘 Casos de Emergência

### Servidor Crítico Inacessível
1. **Imediato:** Contatar administrador via telefone/WhatsApp
2. **Alternativa:** Testar de rede móvel para confirmar problema
3. **Escalação:** Contatar suporte técnico do datacenter
4. **Documentar:** Salvar prints dos erros para suporte

### Perda Total de Conectividade
1. Verificar cabo de rede/WiFi
2. Reiniciar modem/router
3. Testar com hotspot móvel
4. Contatar ISP se persistir

---

## 📝 Resumo Rápido

### 🎯 Soluções Mais Comuns (em ordem de prioridade):

1. **🌐 USAR DOMÍNIO** → ssh usuario@meudominio.com (mais confiável)
2. **☁️ CONFIGURAR CLOUDFLARE** → Registro A com proxy desabilitado  
3. **📱 TESTAR DE OUTRA REDE** → Confirmar se é problema do ISP
4. **📞 CONTATAR ADMINISTRADOR** → Para servidores inacessíveis

### 🔍 Diagnóstico Rápido:

```bash
# 1. Verificar DNS
nslookup meudominio.com

# 2. Testar conectividade básica
ping meudominio.com

# 3. Testar porta SSH específica  
Test-NetConnection meudominio.com -Port 22

# 4. Rastrear rota
tracert meudominio.com
```

### ☁️ Cloudflare - Configuração SSH:

```
Tipo: A
Nome: ssh (ou @)  
IPv4: [IP-DO-SERVIDOR]
Proxy: 🔴 DESABILITADO (nuvem cinza)
```

### 📧 Modelos de Mensagem Prontos:

**Para solicitar informações:**
```
Preciso conectar via SSH ao servidor.
Vocês têm domínio configurado ou IP público?
Qual porta SSH está configurada?
Usuário: [seu-usuario]
```

**Para servidor inacessível:**
```
Servidor [nome] está completamente inacessível.
Domínio não resolve ou todas as portas falham.
Por favor verificar status urgentemente.
```

---

**🔥 LEMBRE-SE:** Use sempre **domínio com Cloudflare** ao invés de IP direto. É mais confiável e profissional!
