# 🔧 Solução para Problemas de Conexão SSH IPv6

## 🚨 Problema Identificado

**Erro:** `ssh: connect to host [IPv6] port 22: Unknown error`
**Causa:** Sua conexão de internet não possui IPv6 configurado globalmente.

## ✅ Soluções Práticas

### 1. **Solicitar IPv4 Alternativo (Recomendado)**

Contate o administrador do servidor e solicite:
```bash
# Perguntar se existe um endereço IPv4 equivalente
# Exemplo: Se o IPv6 é 2804:3dc8:211:2dea:c559:d519:faa9:1ed0
# Pode haver um IPv4 como: 200.100.50.25
```

### 2. **Configurar Túnel IPv6 (Avançado)**

Se precisar urgentemente de IPv6:

**Passo 1:** Acesse https://tunnelbroker.net/
**Passo 2:** Crie conta gratuita
**Passo 3:** Configure um túnel IPv6
**Passo 4:** Siga instruções para Windows

### 3. **Verificar com seu Provedor de Internet**

```bash
# Contatar ISP para:
# - Verificar se oferecem IPv6
# - Solicitar habilitação do IPv6
# - Verificar se é necessário configuração adicional
```

### 4. **Usar VPN com Suporte IPv6**

Algumas VPNs oferecem túneis IPv6:
- ExpressVPN
- NordVPN  
- ProtonVPN

## 🔍 Comandos de Diagnóstico

### Windows - Verificar Status IPv6
```powershell
# Verificar configuração atual
ipconfig /all | findstr IPv6

# Verificar se IPv6 está habilitado
netsh interface ipv6 show config

# Testar conectividade IPv6 global
ping -6 ipv6.google.com
```

### Testar Conectividade Específica
```bash
# Teste básico de conectividade
ping -6 [endereço-ipv6]

# Teste de resolução DNS
nslookup [endereço-ipv6]

# Teste de conexão TCP (se telnet estiver instalado)
telnet [endereço-ipv6] 22
```

## 🎯 Recomendação Imediata

**Solicite ao administrador do servidor:**

1. **Endereço IPv4 alternativo** para conexão SSH
2. **Nome de domínio** que resolva para IPv4
3. **Porta personalizada** se disponível

**Exemplo de mensagem:**
```
Olá, estou tentando conectar via SSH ao endereço IPv6:
2804:3dc8:211:2dea:c559:d519:faa9:1ed0

Minha conexão não suporta IPv6. Vocês têm um endereço IPv4 
alternativo ou nome de domínio que eu possa usar?

Usuário: avelar-serve
```

## 🚀 Conexão Alternativa Temporária

Se o servidor tiver nome de domínio ou IPv4:
```bash
# Conectar via nome de domínio
ssh avelar-serve@servidor.exemplo.com

# Conectar via IPv4
ssh avelar-serve@192.168.1.100

# Conectar com porta personalizada
ssh -p 2222 avelar-serve@servidor.exemplo.com
```

---

## 🚨 Problema Adicional: SSH IPv4 em Redes Diferentes

### ❌ Erro: "Connection timed out" com IPv4

**Causa:** Tentativa de conectar a endereços IPv4 de redes diferentes.

**Exemplo:**
- Sua rede: `192.168.18.99` (rede 192.168.18.x)
- Servidor: `192.168.1.3` (rede 192.168.1.x)

### ✅ Soluções para Redes Diferentes

#### 1. **Verificar Endereço Correto**
```bash
# Perguntar ao administrador o endereço correto
# Pode ser um IP público ao invés de local
```

#### 2. **Configurar Roteamento (Avançado)**
```bash
# Windows - Adicionar rota estática
route add 192.168.1.0 mask 255.255.255.0 192.168.18.1

# Verificar tabela de rotas
route print
```

#### 3. **Usar VPN ou Túnel**
```bash
# Conectar à mesma VPN/rede do servidor
# Ou usar túnel SSH através de servidor intermediário
```

#### 4. **Port Forwarding no Router**
```bash
# Se o servidor está atrás de router,
# configurar port forwarding 22 -> IP interno
```

### 🔍 Comandos de Diagnóstico Rede

```bash
# Windows - Ver sua rede
ipconfig | findstr IPv4

# Windows - Ver dispositivos na rede
arp -a

# Testar conectividade
ping [endereço]

# Verificar rotas
route print | findstr 192.168

# Traceroute para ver caminho
tracert [endereço]
```

---

## 🚨 Diagnóstico Completo: Servidor Completamente Inacessível

### ✅ Cenário Testado
- **Domínio:** ssh.avelarcompany.dev.br
- **IPv4:** 160.238.151.146
- **DNS:** Resolve corretamente ✅
- **Conectividade:** FALHA TOTAL ❌

### 🔍 Testes Realizados
```bash
# Portas testadas (todas falharam)
Test-NetConnection 160.238.151.146 -Port 22    # SSH padrão
Test-NetConnection 160.238.151.146 -Port 2222  # SSH alternativo
Test-NetConnection 160.238.151.146 -Port 80    # HTTP
Test-NetConnection 160.238.151.146 -Port 443   # HTTPS
Test-NetConnection 160.238.151.146 -Port 8022  # SSH alternativo

# Usuários testados (todos falharam)
ssh avelar-serve@ssh.avelarcompany.dev.br
ssh root@ssh.avelarcompany.dev.br
ssh -p 2222 root@ssh.avelarcompany.dev.br

# Resultado: Connection timed out em todos os casos
```

### 🎯 Possíveis Causas
1. **Servidor offline/inativo**
2. **Firewall do servidor** bloqueando todo tráfego externo
3. **Firewall do ISP/provedor** bloqueando conexões
4. **Problema de roteamento** (tracert para no salto 8)
5. **DDoS protection** bloqueando conexões

### ✅ Soluções Recomendadas

#### 1. **Verificar Status do Servidor (Urgente)**
```bash
# Contatar administrador para verificar:
# - Servidor está ligado/funcionando?
# - Serviços SSH estão rodando?
# - Firewall permite conexões externas?
# - Houve mudança recente de configuração?
```

#### 2. **Testar de Outra Rede**
```bash
# Teste de hotspot móvel ou outra conexão
# Para descartar problema do ISP atual
```

#### 3. **Verificar Logs do Servidor**
```bash
# No servidor (se houver acesso físico/console):
sudo tail -f /var/log/auth.log      # Tentativas SSH
sudo tail -f /var/log/syslog        # Logs gerais
sudo systemctl status ssh          # Status do SSH
sudo ufw status                     # Status do firewall
```

#### 4. **Verificar Conectividade do Servidor**
```bash
# No servidor:
curl ifconfig.me                    # Verificar IP público
netstat -tuln | grep :22           # SSH rodando?
ss -tuln | grep :22                # Alternativa moderna
```

### 🆘 Ações Imediatas
1. **Contatar administrador** do ssh.avelarcompany.dev.br
2. **Verificar se servidor está online**
3. **Pedir teste de conectividade** de outras localidades
4. **Solicitar acesso via console/KVM** se disponível

---

**💡 Dica:** A maioria dos problemas de SSH IPv6 são resolvidos usando IPv4 ou configurando túneis IPv6 adequados. Para problemas de rede local, verifique sempre se os dispositivos estão na mesma subnet. Quando há falha total de conectividade, o problema geralmente está no servidor ou infraestrutura de rede.
