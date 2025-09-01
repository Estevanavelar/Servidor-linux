# ❓ Perguntas Frequentes (FAQ)

## 🚀 Instalação e Configuração

### Q: Em quais sistemas operacionais funciona?
**A:** O sistema é compatível com:
- Ubuntu 20.04+ (Recomendado)
- Debian 10+
- CentOS 8+
- RHEL 8+

### Q: Quais são os recursos mínimos necessários?
**A:** Recursos mínimos:
- **CPU:** 2 cores
- **RAM:** 4GB (8GB recomendado)
- **Disco:** 50GB livres
- **Rede:** Conexão estável

### Q: Quanto tempo demora a instalação?
**A:** Normalmente entre 15-30 minutos, dependendo da velocidade da internet e do hardware.

### Q: Posso instalar em um VPS?
**A:** Sim! Funciona perfeitamente em VPS de qualquer provedor (AWS, DigitalOcean, Vultr, etc.).

## 🎛️ Painel de Controle

### Q: Como alterar a senha padrão do painel?
**A:** Edite o arquivo `panel/server.js` e altere a linha:
```javascript
const defaultPass = 'SUA_NOVA_SENHA';
```

### Q: O painel é seguro para usar em produção?
**A:** Sim, mas altere sempre as credenciais padrão e configure HTTPS para o painel.

### Q: Posso acessar o painel de qualquer lugar?
**A:** Sim, o painel fica disponível em `http://SEU-IP:8080`. Para maior segurança, configure um firewall.

## 🌐 Gerenciamento de Sites

### Q: Quantos sites posso hospedar?
**A:** Não há limite técnico. Depende apenas dos recursos do seu servidor.

### Q: Como fazer upload de arquivos para um site?
**A:** Você pode:
1. Usar o gerenciador de arquivos do painel
2. Usar SCP/SFTP: `scp -r meusite/* usuario@servidor:/var/www/meusite.com/`
3. Usar Git: `git clone` direto no diretório do site

### Q: Como configurar um subdomínio?
**A:** Use o mesmo comando:
```bash
sudo ./scripts/domain-ssl.sh create-site api.meusite.com
```

### Q: Posso usar o mesmo domínio para múltiplas aplicações?
**A:** Sim, configure diferentes locations no Nginx ou use subdomínios.

## 🔒 SSL e Certificados

### Q: O SSL é realmente gratuito?
**A:** Sim, usa Let's Encrypt que é 100% gratuito e confiável.

### Q: Com que frequência preciso renovar o SSL?
**A:** A renovação é automática. Os certificados Let's Encrypt são válidos por 90 dias e renovam automaticamente.

### Q: E se meu domínio não apontar para o servidor?
**A:** O SSL só funciona se o domínio estiver apontando corretamente. Configure o DNS primeiro.

### Q: Posso usar certificados SSL próprios?
**A:** Sim, você pode configurar manualmente no Nginx.

## 🗄️ Bancos de Dados

### Q: Como acessar o MySQL?
**A:** Via linha de comando:
```bash
sudo mysql -u root -p
```
Ou instale phpMyAdmin para interface web.

### Q: Como criar um novo banco PostgreSQL?
**A:**
```bash
sudo -u postgres createdb meunovo banco
```

### Q: Posso usar o mesmo servidor para múltiplos bancos?
**A:** Sim, tanto MySQL quanto PostgreSQL suportam múltiplos bancos na mesma instância.

### Q: Como fazer backup dos bancos?
**A:** Use o script de backup:
```bash
sudo ./scripts/backup.sh databases
```

## 🔧 Desenvolvimento

### Q: Como configurar um ambiente Node.js?
**A:** 
1. Crie seu app Node.js em `/var/www/meuapp/`
2. Configure proxy reverso no Nginx
3. Use PM2 para gerenciar o processo

### Q: Como usar com aplicações PHP?
**A:** Crie o site com PHP habilitado:
```bash
sudo ./scripts/domain-ssl.sh create-site meusite.com /var/www/meusite yes
```

### Q: Posso usar frameworks como Laravel, WordPress?
**A:** Sim! Apenas configure o document root correto e habilite PHP.

### Q: Como configurar Python/Django?
**A:** Similar ao Node.js, use proxy reverso e um servidor WSGI como Gunicorn.

## 🚨 Problemas Comuns

### Q: "Nginx falhou ao iniciar"
**A:** Verifique a configuração:
```bash
sudo nginx -t
sudo journalctl -u nginx
```

### Q: "Não consigo acessar o painel"
**A:** Verifique se a porta 8080 está liberada:
```bash
sudo ufw allow 8080
sudo lsof -i :8080
```

### Q: "SSL não funciona"
**A:** Certifique-se de que:
1. O domínio aponta para seu servidor
2. As portas 80 e 443 estão abertas
3. Aguarde a propagação do DNS (até 48h)

### Q: "Site mostra página padrão do Nginx"
**A:** Verifique se o site está habilitado:
```bash
sudo ln -sf /etc/nginx/sites-available/meusite.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

### Q: "MySQL/PostgreSQL não conecta"
**A:** Verifique se os serviços estão rodando:
```bash
sudo systemctl status mysql postgresql
```

## 🔄 Manutenção

### Q: Como fazer backup completo?
**A:**
```bash
sudo ./scripts/backup.sh full
```

### Q: Como atualizar o sistema?
**A:**
```bash
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL
```

### Q: Com que frequência devo fazer backup?
**A:** Recomendamos backup diário automatizado. O script já configura isso.

### Q: Como monitorar o desempenho?
**A:** Use as ferramentas instaladas:
```bash
htop        # Processos e CPU
nload       # Rede
iotop       # Disco
df -h       # Espaço em disco
```

## 🔧 Personalização

### Q: Como personalizar as configurações do Nginx?
**A:** Edite `/etc/nginx/nginx.conf` ou crie configurações específicas em `/etc/nginx/sites-available/`.

### Q: Posso adicionar mais linguagens de programação?
**A:** Sim! Instale via package manager e configure conforme necessário.

### Q: Como adicionar mais ferramentas ao painel?
**A:** O painel é desenvolvido em Node.js. Você pode modificar o código em `panel/`.

### Q: Posso integrar com CI/CD?
**A:** Sim! Configure webhooks ou integre com ferramentas como Jenkins, GitLab CI, etc.

## 📊 Performance

### Q: Como otimizar o desempenho?
**A:**
1. Configure cache no Nginx
2. Otimize configurações do MySQL/PostgreSQL
3. Use Redis para cache de aplicação
4. Configure CDN se necessário

### Q: Quantas requisições simultâneas suporta?
**A:** Depende dos recursos do servidor. Nginx pode lidar com milhares de conexões simultâneas.

### Q: Como escalar para mais tráfego?
**A:**
1. Aumentar recursos do servidor
2. Usar load balancer
3. Configurar cache
4. Otimizar banco de dados

## 🔐 Segurança

### Q: O sistema é seguro?
**A:** Sim, implementa várias camadas de segurança:
- SSH hardening
- Fail2Ban
- Firewall configurado
- Headers de segurança
- SSL/TLS obrigatório

### Q: Como proteger ainda mais?
**A:**
1. Alterar portas padrão
2. Usar chaves SSH apenas
3. Configurar VPN
4. Monitoramento de logs
5. Atualizações regulares

### Q: Preciso de antivírus?
**A:** Para servidores Linux, antivírus não é necessário. Mantenha o sistema atualizado e monitore logs.

## 💰 Custos

### Q: Há algum custo para usar o sistema?
**A:** O sistema é 100% gratuito. Custos podem incluir:
- VPS/servidor (variável)
- Domínio (~R$ 40/ano)
- Certificados SSL são gratuitos

### Q: Preciso pagar por licenças?
**A:** Não! Todas as tecnologias usadas são open source e gratuitas.

## 📞 Suporte

### Q: Onde obter ajuda?
**A:**
1. Consulte esta documentação
2. Verifique os logs do sistema
3. Abra issue no GitHub
4. Consulte a comunidade

### Q: Como reportar bugs?
**A:**
1. Descreva o problema detalhadamente
2. Inclua logs relevantes
3. Mencione a versão do sistema operacional
4. Forneça passos para reproduzir

### Q: Posso contribuir com o projeto?
**A:** Sim! Contribuições são bem-vindas:
1. Fork do repositório
2. Crie branch para sua feature
3. Teste em ambiente limpo
4. Submeta pull request

---

## 💡 Dicas Extras

### Comandos Úteis
```bash
# Ver status de todos os serviços
sudo systemctl status nginx mysql postgresql redis php8.1-fpm

# Monitorar logs em tempo real
sudo tail -f /var/log/nginx/access.log

# Verificar uso de disco
df -h

# Ver processos que usam mais CPU
top

# Verificar conexões de rede
ss -tuln

# Listar sites configurados
./scripts/domain-ssl.sh list-sites
```

### Estrutura de Diretórios
```
/var/www/               # Sites
/etc/nginx/             # Configurações Nginx
/var/log/nginx/         # Logs Nginx
/backups/               # Backups automáticos
/.lixeira/              # Arquivos removidos
```

**Não encontrou sua pergunta? Crie uma issue no GitHub!** 🚀
