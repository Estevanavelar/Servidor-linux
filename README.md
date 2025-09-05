# 🚀 Sistema Completo de Servidor Linux

**Configuração automatizada de servidor Linux com painel de controle web moderno**

[![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)](https://www.linux.org/)
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=flat&logo=nginx&logoColor=white)](https://nginx.org/)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=flat&logo=node.js&logoColor=white)](https://nodejs.org/)
[![PHP](https://img.shields.io/badge/PHP-777BB4?style=flat&logo=php&logoColor=white)](https://www.php.net/)
[![MySQL](https://img.shields.io/badge/MySQL-00000F?style=flat&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🎯 Visão Geral

Este projeto oferece uma **solução completa e automatizada** para configurar e gerenciar servidores Linux, incluindo:

- 🔧 **Instalação automática** de todas as dependências
- 🎛️ **Painel de controle web** moderno e intuitivo  
- 🌐 **Gerenciamento visual** de domínios e SSL
- 📊 **Monitoramento em tempo real** do sistema
- 🔒 **Segurança** configurada automaticamente
- 💾 **Backup automático** de sites e configurações

## ⚡ Instalação Ultra-Rápida (1 comando)

### 🚀 Para Instalação na Pasta Root (Recomendado)
```bash
# Execute como root - substitua pelo seu domínio e email
sudo su -
bash <(curl -s https://raw.githubusercontent.com/seu-usuario/servidor-linux/main/install-root.sh) panel.seudominio.com admin@seudominio.com
```

### 📋 Instalação Manual (Método Alternativo)
```bash
# 1. Baixar o projeto na pasta root
sudo su -
cd /root
git clone https://github.com/Estevanavelar/servidor-linux.git
cd servidor-linux

# 2. Configurar com domínio
chmod +x scripts/*.sh
./scripts/setup-panel-domain.sh panel.seudominio.com admin@seudominio.com
```

🌐 **Acessar painel:** `https://panel.seudominio.com`  
👤 **Login:** `admin` / `1583`  
🔐 **SSL:** Automático via Let's Encrypt  
🔄 **Auto-start:** Configurado no boot do sistema

## 📋 O Que é Instalado Automaticamente

### 🌐 Servidor Web
- **Nginx** - Servidor web de alta performance
- Configurações otimizadas para produção
- Gzip, cache, headers de segurança

### 💻 Linguagens
- **Node.js 18** + npm + yarn + TypeScript
- **PHP 8.1** + FPM + extensões essenciais
- **Python 3** + pip + virtualenv

### 🗄️ Bancos de Dados
- **MySQL** - Banco relacional completo
- **PostgreSQL** - Banco robusto para aplicações
- **SQLite** - Banco leve para projetos menores
- **Redis** - Cache em memória

### 🔒 Segurança
- **SSH** configurado com melhores práticas
- **Fail2Ban** proteção contra ataques
- **Firewall** (UFW/Firewalld) configurado
- **SSL/TLS** automático via Let's Encrypt

## 🎛️ Painel de Controle

### Recursos do Painel:
- 📊 **Dashboard em tempo real** - CPU, memória, disco, uptime
- 🌐 **Gerenciador de sites** - Criar, editar, ativar/desativar
- 🔒 **Certificados SSL** - Obtenção automática e renovação
- 📁 **Gerenciador de arquivos** - Upload e navegação web
- 🗄️ **Gerenciador de bancos** - MySQL, PostgreSQL, SQLite
- 📋 **Logs em tempo real** - WebSocket para monitoramento
- ⚙️ **Configurações** - Backup, segurança, sistema

![Painel Screenshot](docs/assets/panel-screenshot.png)

## 🌐 Gerenciamento Simplificado

### Criar Novo Site
```bash
# Site básico
sudo ./scripts/domain-ssl.sh create-site meusite.com

# Site com PHP
sudo ./scripts/domain-ssl.sh create-site meusite.com /var/www/meusite yes
```

### Instalar SSL Automático
```bash
sudo ./scripts/domain-ssl.sh install-ssl meusite.com admin@meusite.com
```

### Backup Completo
```bash
sudo ./scripts/backup.sh full
```

## 📁 Estrutura do Projeto

```
├── scripts/           # Scripts de instalação e configuração
│   ├── install-server.sh     # Instalação completa automatizada
│   ├── domain-ssl.sh         # Gerenciamento de domínios e SSL
│   ├── start-panel.sh        # Inicialização do painel
│   └── backup.sh             # Sistema de backup
├── panel/            # Painel de controle web
│   ├── server.js            # Servidor backend Node.js
│   ├── package.json         # Dependências
│   └── public/              # Frontend (HTML/CSS/JS)
├── configs/          # Configurações e snippets
├── docs/             # Documentação completa
│   ├── GUIA_COMPLETO.md     # Manual detalhado
│   ├── INSTALACAO.md        # Guia de instalação
│   └── FAQ.md               # Perguntas frequentes
├── .lixeira/         # Arquivos removidos (backup)
└── README.md         # Este arquivo
```

## 🚀 Casos de Uso

### Para Desenvolvedores
- Ambiente de desenvolvimento completo
- Deploy automático de aplicações
- Múltiplas linguagens e bancos
- Gerenciamento visual de projetos

### Para Agências
- Hospedagem de múltiplos sites
- Gerenciamento centralizado
- SSL automático para todos os clientes
- Backup automático

### Para SysAdmins
- Configuração padronizada
- Monitoramento em tempo real
- Segurança configurada automaticamente
- Automação de tarefas

## 📊 Compatibilidade

| Sistema | Versão | Status |
|---------|--------|--------|
| Ubuntu  | 20.04+ | ✅ Testado |
| Debian  | 10+    | ✅ Testado |
| CentOS  | 8+     | ✅ Compatível |
| RHEL    | 8+     | ✅ Compatível |

## 📖 Documentação

### 📚 Guias Disponíveis
- **[Instalação Root](docs/INSTALACAO_ROOT.md)** - 🔥 Instalação na pasta root (NOVO)
- **[Painel Profissional](docs/PAINEL_PROFISSIONAL.md)** - Guia completo do painel moderno
- **[Solução SSH](docs/SOLUCAO_SSH.md)** - Resolver problemas SSH com Cloudflare
- **[Guia Completo](docs/GUIA_COMPLETO.md)** - Manual detalhado do sistema
- **[Guia de Instalação](docs/INSTALACAO.md)** - Instalação tradicional
- **[FAQ](docs/FAQ.md)** - Perguntas frequentes e soluções
- **[Comandos Linux](COMANDOS_LINUX.md)** - Referência completa de comandos

### 🎥 Recursos Adicionais
- Exemplos de configuração
- Scripts de automação
- Troubleshooting guides
- Best practices

## 🔧 Requisitos do Sistema

### Mínimo
- **CPU:** 2 cores
- **RAM:** 4GB
- **Disco:** 50GB livres
- **SO:** Linux (Ubuntu 20.04+ recomendado)

### Recomendado
- **CPU:** 4+ cores
- **RAM:** 8GB+
- **Disco:** 100GB+ SSD
- **Rede:** Conexão estável

## 🌟 Características Avançadas

### Automação Completa
- Instalação zero-touch
- Configuração de segurança automática
- Backup e renovação SSL automática
- Monitoramento proativo

### Escalabilidade
- Suporte a múltiplos sites
- Configuração de proxy reverso
- Load balancing ready
- Database clustering

### Segurança Enterprise
- SSH hardening automático
- Fail2Ban configurado
- Firewall otimizado
- Headers de segurança

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. **Fork** este repositório
2. **Crie** uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. **Push** para a branch (`git push origin feature/AmazingFeature`)
5. **Abra** um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## ⭐ Agradecimentos

- Comunidade open source
- Contribuidores do projeto
- Testadores e usuários

## 🚨 Solução de Problemas

### 🔌 Conectividade SSH
Problemas para conectar via SSH? **[Consulte nosso guia completo](docs/SOLUCAO_SSH.md)** que resolve:

- 🌐 **Conexão via domínio** → ssh usuario@meudominio.com
- ☁️ **Configuração Cloudflare** → Registro A com proxy desabilitado
- ❌ **"Connection timed out"** → Verificar DNS/firewall  
- ❌ **Servidor inacessível** → Diagnóstico completo
- 📧 **Modelos de mensagem** → Para contatar administradores

**Diagnóstico rápido:**
```bash
# Verificar DNS e conectividade
nslookup meudominio.com
ping meudominio.com
Test-NetConnection meudominio.com -Port 22
```

### 🌐 Painel Web
```bash
# Verificar se painel está rodando
sudo lsof -i :8080

# Verificar logs do painel
pm2 logs server-panel

# Reiniciar painel
pm2 restart server-panel
```

## 📞 Suporte

- 📖 **Documentação:** [docs/](docs/)
- 🐛 **Bugs:** [Issues](https://github.com/Estevanavelar/servidor-linux/issues)
- 💬 **Discussões:** [Discussions](https://github.com/Estevanavelar/servidor-linux/discussions)
- 📧 **Email:** suporte@seudominio.com

---

<div align="center">

**🚀 Transforme qualquer servidor Linux em uma infraestrutura profissional com apenas um comando!**

[⬆️ Voltar ao topo](#-sistema-completo-de-servidor-linux)

</div>
