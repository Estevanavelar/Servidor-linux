// Estado da aplicação
let authToken = localStorage.getItem('authToken');
let currentSection = 'overview';
let currentPath = '/var/www';
let websocket = null;

// Inicialização
document.addEventListener('DOMContentLoaded', function() {
    checkAuth();
    setupEventListeners();
    setupWebSocket();
});

// Verificar autenticação
function checkAuth() {
    if (authToken) {
        showDashboard();
        loadDashboardData();
    } else {
        showLogin();
    }
}

// Mostrar tela de login
function showLogin() {
    document.getElementById('loading').style.display = 'none';
    document.getElementById('loginScreen').style.display = 'flex';
    document.getElementById('dashboard').style.display = 'none';
}

// Mostrar dashboard
function showDashboard() {
    document.getElementById('loading').style.display = 'none';
    document.getElementById('loginScreen').style.display = 'none';
    document.getElementById('dashboard').style.display = 'flex';
}

// Setup de event listeners
function setupEventListeners() {
    // Login form
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    
    // Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', handleNavigation);
    });
    
    // Logout
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);
    
    // Modal controls
    setupModalControls();
    
    // Site management
    document.getElementById('addSiteBtn').addEventListener('click', () => {
        showModal('addSiteModal');
    });
    
    document.getElementById('addSiteForm').addEventListener('submit', handleAddSite);
    
    // SSL management
    document.getElementById('obtainSslBtn').addEventListener('click', () => {
        showModal('sslModal');
    });
    
    document.getElementById('sslForm').addEventListener('submit', handleObtainSsl);
    
    // File management
    document.getElementById('refreshFilesBtn').addEventListener('click', loadFiles);
    
    // Sidebar toggle for mobile
    document.querySelector('.sidebar-toggle').addEventListener('click', toggleSidebar);
}

// Handle login
async function handleLogin(e) {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorDiv = document.getElementById('loginError');
    
    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username, password })
        });
        
        const data = await response.json();
        
        if (data.success) {
            authToken = data.token;
            localStorage.setItem('authToken', authToken);
            showDashboard();
            loadDashboardData();
        } else {
            errorDiv.textContent = data.error || 'Erro no login';
            errorDiv.style.display = 'block';
        }
    } catch (error) {
        errorDiv.textContent = 'Erro de conexão';
        errorDiv.style.display = 'block';
    }
}

// Handle logout
function handleLogout() {
    authToken = null;
    localStorage.removeItem('authToken');
    showLogin();
    if (websocket) {
        websocket.close();
    }
}

// Handle navigation
function handleNavigation(e) {
    e.preventDefault();
    
    const section = e.currentTarget.dataset.section;
    
    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    e.currentTarget.classList.add('active');
    
    // Update page title
    const titles = {
        overview: 'Visão Geral',
        sites: 'Sites & Domínios',
        ssl: 'Certificados SSL',
        files: 'Gerenciador de Arquivos',
        databases: 'Bancos de Dados',
        logs: 'Logs do Sistema',
        settings: 'Configurações'
    };
    
    document.getElementById('pageTitle').textContent = titles[section];
    
    // Show section
    document.querySelectorAll('.section').forEach(sec => {
        sec.classList.remove('active');
    });
    document.getElementById(`${section}-section`).classList.add('active');
    
    currentSection = section;
    
    // Load section data
    loadSectionData(section);
}

// Load dashboard data
async function loadDashboardData() {
    loadSystemStatus();
    loadSites();
}

// Load section specific data
function loadSectionData(section) {
    switch (section) {
        case 'overview':
            loadSystemStatus();
            break;
        case 'sites':
            loadSites();
            break;
        case 'files':
            loadFiles();
            break;
        case 'logs':
            loadLogs();
            break;
    }
}

// Load system status
async function loadSystemStatus() {
    try {
        const response = await apiRequest('/api/system/status');
        const data = await response.json();
        
        if (data.success) {
            updateSystemStatus(data.data);
        }
    } catch (error) {
        console.error('Erro ao carregar status do sistema:', error);
    }
}

// Update system status display
function updateSystemStatus(status) {
    // Parse uptime
    if (status.uptime) {
        const uptimeMatch = status.uptime.match(/up\s+(.+?),/);
        if (uptimeMatch) {
            document.getElementById('uptime').textContent = uptimeMatch[1];
        }
    }
    
    // Parse memory
    if (status.memory) {
        const lines = status.memory.split('\n');
        const memLine = lines.find(line => line.startsWith('Mem:'));
        if (memLine) {
            const parts = memLine.split(/\s+/);
            const total = parseInt(parts[1]);
            const used = parseInt(parts[2]);
            const totalGB = (total / 1024).toFixed(1);
            const usedGB = (used / 1024).toFixed(1);
            document.getElementById('memoryUsage').textContent = `${usedGB}GB / ${totalGB}GB`;
        }
    }
    
    // Parse CPU load
    if (status.cpu) {
        const loadAvg = status.cpu.split(' ')[0];
        document.getElementById('cpuLoad').textContent = loadAvg;
    }
    
    // Parse disk usage
    if (status.disk) {
        const lines = status.disk.split('\n');
        const rootLine = lines.find(line => line.includes('/'));
        if (rootLine) {
            const parts = rootLine.split(/\s+/);
            const usage = parts[4];
            const used = parts[2];
            const total = parts[1];
            document.getElementById('diskUsage').textContent = `${used} / ${total}`;
            
            // Update progress bar
            const percentage = parseInt(usage.replace('%', ''));
            document.querySelector('.progress').style.width = `${percentage}%`;
        }
    }
}

// Load sites list
async function loadSites() {
    try {
        const response = await apiRequest('/api/nginx/sites');
        const data = await response.json();
        
        if (data.success) {
            updateSitesTable(data.data);
            document.getElementById('activeSites').textContent = data.data.length;
        }
    } catch (error) {
        console.error('Erro ao carregar sites:', error);
    }
}

// Update sites table
function updateSitesTable(sites) {
    const tbody = document.getElementById('sitesTableBody');
    tbody.innerHTML = '';
    
    sites.forEach(site => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${site.serverName}</td>
            <td>
                <span class="status ${site.enabled ? 'running' : 'stopped'}">
                    ${site.enabled ? 'Ativo' : 'Inativo'}
                </span>
            </td>
            <td>
                <span class="status ${site.ssl ? 'running' : 'stopped'}">
                    ${site.ssl ? 'Ativo' : 'Inativo'}
                </span>
            </td>
            <td><code>${site.configPath}</code></td>
            <td>
                <button class="btn btn-secondary btn-sm" onclick="toggleSite('${site.name}', ${!site.enabled})">
                    ${site.enabled ? 'Desativar' : 'Ativar'}
                </button>
                <button class="btn btn-danger btn-sm" onclick="deleteSite('${site.name}')">
                    Excluir
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Toggle site status
async function toggleSite(siteName, enable) {
    try {
        const response = await apiRequest(`/api/nginx/sites/${siteName}`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ action: enable ? 'enable' : 'disable' })
        });
        
        const data = await response.json();
        
        if (data.success) {
            showNotification(data.message, 'success');
            loadSites();
        } else {
            showNotification(data.error, 'error');
        }
    } catch (error) {
        showNotification('Erro ao alterar status do site', 'error');
    }
}

// Handle add site
async function handleAddSite(e) {
    e.preventDefault();
    
    const formData = {
        domain: document.getElementById('siteDomain').value,
        documentRoot: document.getElementById('siteRoot').value,
        phpEnabled: document.getElementById('enablePhp').checked,
        sslEnabled: document.getElementById('enableSsl').checked
    };
    
    try {
        const response = await apiRequest('/api/nginx/sites', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            showNotification(data.message, 'success');
            hideModal('addSiteModal');
            loadSites();
            document.getElementById('addSiteForm').reset();
        } else {
            showNotification(data.error, 'error');
        }
    } catch (error) {
        showNotification('Erro ao criar site', 'error');
    }
}

// Handle obtain SSL
async function handleObtainSsl(e) {
    e.preventDefault();
    
    const formData = {
        domain: document.getElementById('sslDomain').value,
        email: document.getElementById('sslEmail').value
    };
    
    try {
        const response = await apiRequest('/api/ssl/obtain', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            showNotification(data.message, 'success');
            hideModal('sslModal');
            document.getElementById('sslForm').reset();
        } else {
            showNotification(data.error, 'error');
        }
    } catch (error) {
        showNotification('Erro ao obter certificado SSL', 'error');
    }
}

// Load files
async function loadFiles(path = currentPath) {
    try {
        const response = await apiRequest(`/api/files?path=${encodeURIComponent(path)}`);
        const data = await response.json();
        
        if (data.success) {
            updateFilesGrid(data.data.files);
            currentPath = data.data.path;
            document.getElementById('currentPath').textContent = currentPath;
        }
    } catch (error) {
        console.error('Erro ao carregar arquivos:', error);
    }
}

// Update files grid
function updateFilesGrid(files) {
    const grid = document.getElementById('filesGrid');
    grid.innerHTML = '';
    
    // Add parent directory if not root
    if (currentPath !== '/') {
        const parentItem = document.createElement('div');
        parentItem.className = 'file-item folder';
        parentItem.innerHTML = `
            <i class="fas fa-arrow-up"></i>
            <span>..</span>
        `;
        parentItem.addEventListener('click', () => {
            const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/';
            loadFiles(parentPath);
        });
        grid.appendChild(parentItem);
    }
    
    files.forEach(file => {
        const fileItem = document.createElement('div');
        fileItem.className = `file-item ${file.isDirectory ? 'folder' : 'file'}`;
        fileItem.innerHTML = `
            <i class="fas fa-${file.isDirectory ? 'folder' : 'file'}"></i>
            <span>${file.name}</span>
        `;
        
        if (file.isDirectory) {
            fileItem.addEventListener('click', () => {
                loadFiles(file.path);
            });
        }
        
        grid.appendChild(fileItem);
    });
}

// Load logs
function loadLogs() {
    const logViewer = document.getElementById('logViewer');
    
    // Simulate log updates
    const logs = [
        '[2024-01-09 15:30:01] 192.168.1.100 - GET / HTTP/1.1 200',
        '[2024-01-09 15:30:05] 192.168.1.101 - GET /api/status HTTP/1.1 200',
        '[2024-01-09 15:30:10] Sistema de backup iniciado',
        '[2024-01-09 15:30:15] SSL renovado para exemplo.com',
        '[2024-01-09 15:30:20] 192.168.1.102 - POST /api/sites HTTP/1.1 201'
    ];
    
    logViewer.innerHTML = logs.map(log => `<div class="log-line">${log}</div>`).join('');
}

// WebSocket setup for real-time logs
function setupWebSocket() {
    if (!authToken) return;
    
    try {
        websocket = new WebSocket('ws://localhost:8081');
        
        websocket.onopen = function() {
            console.log('WebSocket conectado');
        };
        
        websocket.onmessage = function(event) {
            const data = JSON.parse(event.data);
            
            if (data.type === 'nginx_access' && currentSection === 'logs') {
                const logViewer = document.getElementById('logViewer');
                const logLine = document.createElement('div');
                logLine.className = 'log-line';
                logLine.textContent = data.data.trim();
                logViewer.appendChild(logLine);
                logViewer.scrollTop = logViewer.scrollHeight;
            }
        };
        
        websocket.onclose = function() {
            console.log('WebSocket desconectado');
            // Tentar reconectar após 5 segundos
            setTimeout(setupWebSocket, 5000);
        };
        
        websocket.onerror = function(error) {
            console.error('Erro no WebSocket:', error);
        };
    } catch (error) {
        console.error('Erro ao conectar WebSocket:', error);
    }
}

// Modal controls
function setupModalControls() {
    // Close buttons
    document.querySelectorAll('.modal-close, .modal-cancel').forEach(btn => {
        btn.addEventListener('click', function() {
            const modal = this.closest('.modal');
            hideModal(modal.id);
        });
    });
    
    // Click outside to close
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', function(e) {
            if (e.target === this) {
                hideModal(this.id);
            }
        });
    });
}

// Show modal
function showModal(modalId) {
    document.getElementById(modalId).style.display = 'flex';
}

// Hide modal
function hideModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

// Toggle sidebar (mobile)
function toggleSidebar() {
    document.querySelector('.sidebar').classList.toggle('open');
}

// API request helper
async function apiRequest(url, options = {}) {
    const defaultOptions = {
        headers: {
            'Authorization': `Bearer ${authToken}`,
            'Content-Type': 'application/json'
        }
    };
    
    const mergedOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers
        }
    };
    
    const response = await fetch(url, mergedOptions);
    
    if (response.status === 401) {
        handleLogout();
        throw new Error('Não autorizado');
    }
    
    return response;
}

// Show notification
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'times' : 'info'}"></i>
        <span>${message}</span>
    `;
    
    // Add styles
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${type === 'success' ? 'var(--success-color)' : type === 'error' ? 'var(--danger-color)' : 'var(--primary-color)'};
        color: white;
        padding: 15px 20px;
        border-radius: var(--border-radius);
        box-shadow: var(--shadow);
        z-index: 10001;
        display: flex;
        align-items: center;
        gap: 10px;
        opacity: 0;
        transform: translateX(100%);
        transition: all 0.3s;
    `;
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.opacity = '1';
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after 5 seconds
    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 5000);
}

// Auto-refresh system status every 30 seconds
setInterval(() => {
    if (authToken && currentSection === 'overview') {
        loadSystemStatus();
    }
}, 30000);
