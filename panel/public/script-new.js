/**
 * Professional Server Control Panel
 * Advanced JavaScript with real-time monitoring and modern UX
 */

class ServerPanel {
    constructor() {
        this.authToken = localStorage.getItem('authToken');
        this.currentSection = 'dashboard';
        this.socket = null;
        this.charts = {};
        this.refreshInterval = null;
        this.notifications = [];
        
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.checkAuth();
        this.initializeCharts();
        
        // Hide loading screen after initialization
        setTimeout(() => {
            document.getElementById('loadingScreen').classList.add('hidden');
        }, 1000);
    }
    
    // Authentication Methods
    checkAuth() {
        if (this.authToken && this.isValidToken()) {
            this.showDashboard();
            this.connectWebSocket();
            this.startDataRefresh();
        } else {
            this.showLogin();
        }
    }
    
    isValidToken() {
        try {
            const payload = JSON.parse(atob(this.authToken.split('.')[1]));
            return payload.exp > Date.now() / 1000;
        } catch (error) {
            return false;
        }
    }
    
    async login(username, password) {
        try {
            const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.authToken = data.token;
                localStorage.setItem('authToken', this.authToken);
                this.showDashboard();
                this.connectWebSocket();
                this.startDataRefresh();
                return { success: true };
            } else {
                return { success: false, error: data.error };
            }
        } catch (error) {
            return { success: false, error: 'Erro de conexão' };
        }
    }
    
    logout() {
        this.authToken = null;
        localStorage.removeItem('authToken');
        if (this.socket) this.socket.close();
        if (this.refreshInterval) clearInterval(this.refreshInterval);
        this.showLogin();
    }
    
    // UI Methods
    showLogin() {
        document.getElementById('loginScreen').classList.remove('hidden');
        document.getElementById('dashboard').classList.add('hidden');
    }
    
    showDashboard() {
        document.getElementById('loginScreen').classList.add('hidden');
        document.getElementById('dashboard').classList.remove('hidden');
    }
    
    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.section-content').forEach(section => {
            section.classList.add('hidden');
        });
        
        // Show selected section
        const section = document.getElementById(`${sectionName}Section`);
        if (section) {
            section.classList.remove('hidden');
            this.currentSection = sectionName;
            
            // Update page title
            const title = sectionName.charAt(0).toUpperCase() + sectionName.slice(1);
            document.getElementById('pageTitle').textContent = title;
            
            // Update navigation
            document.querySelectorAll('.nav-link').forEach(link => {
                link.classList.remove('bg-primary-50', 'text-primary-700', 'border-r-2', 'border-primary-600');
                if (link.dataset.section === sectionName) {
                    link.classList.add('bg-primary-50', 'text-primary-700', 'border-r-2', 'border-primary-600');
                }
            });
            
            // Load section-specific data
            this.loadSectionData(sectionName);
        }
    }
    
    // Event Listeners
    setupEventListeners() {
        // Login form
        document.getElementById('loginForm').addEventListener('submit', this.handleLogin.bind(this));
        
        // Navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const section = e.currentTarget.dataset.section;
                this.showSection(section);
            });
        });
        
        // Logout
        document.getElementById('logoutBtn').addEventListener('click', this.logout.bind(this));
        
        // Sidebar toggle for mobile
        document.getElementById('openSidebar').addEventListener('click', this.openSidebar);
        document.getElementById('closeSidebar').addEventListener('click', this.closeSidebar);
        
        // Add hosting button
        document.getElementById('addHostingBtn').addEventListener('click', this.showAddHostingModal.bind(this));
    }
    
    async handleLogin(e) {
        e.preventDefault();
        
        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const errorDiv = document.getElementById('loginError');
        
        const result = await this.login(username, password);
        
        if (result.success) {
            errorDiv.classList.add('hidden');
        } else {
            errorDiv.textContent = result.error;
            errorDiv.classList.remove('hidden');
        }
    }
    
    // WebSocket Connection
    connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/socket.io/`;
        
        try {
            this.socket = io(wsUrl, {
                auth: { token: this.authToken }
            });
            
            this.socket.on('connect', () => {
                console.log('WebSocket connected');
                this.updateConnectionStatus(true);
            });
            
            this.socket.on('disconnect', () => {
                console.log('WebSocket disconnected');
                this.updateConnectionStatus(false);
            });
            
            this.socket.on('system_update', (data) => {
                this.updateSystemData(data);
            });
            
            this.socket.on('notification', (notification) => {
                this.showNotification(notification);
            });
            
        } catch (error) {
            console.error('WebSocket connection failed:', error);
        }
    }
    
    updateConnectionStatus(connected) {
        const statusIndicator = document.querySelector('.w-2.h-2');
        if (connected) {
            statusIndicator.className = 'w-2 h-2 bg-green-500 rounded-full animate-pulse-slow';
        } else {
            statusIndicator.className = 'w-2 h-2 bg-red-500 rounded-full';
        }
    }
    
    // Data Management
    async fetchData(endpoint) {
        try {
            const response = await fetch(endpoint, {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (response.ok) {
                return await response.json();
            } else if (response.status === 401) {
                this.logout();
                return null;
            } else {
                throw new Error(`HTTP ${response.status}`);
            }
        } catch (error) {
            console.error('Fetch error:', error);
            this.showNotification({
                type: 'error',
                message: `Erro ao carregar dados: ${error.message}`
            });
            return null;
        }
    }
    
    async loadSystemStats() {
        const data = await this.fetchData('/api/system/stats');
        if (data && data.success) {
            this.updateDashboardStats(data.data);
        }
    }
    
    updateDashboardStats(stats) {
        // Update stat cards
        document.getElementById('activeSites').textContent = stats.sites?.active || 0;
        document.getElementById('sslCount').textContent = stats.ssl?.active || 0;
        document.getElementById('dbCount').textContent = stats.databases?.total || 0;
        document.getElementById('diskUsage').textContent = `${stats.system?.diskUsage || 0}%`;
        
        // Update charts
        if (this.charts.cpu && stats.system?.cpu) {
            this.updateChart('cpu', stats.system.cpu);
        }
        
        if (this.charts.memory && stats.system?.memory) {
            this.updateChart('memory', stats.system.memory);
        }
    }
    
    updateSystemData(data) {
        // Real-time updates via WebSocket
        if (data.type === 'stats') {
            this.updateDashboardStats(data.data);
        } else if (data.type === 'service_status') {
            this.updateServiceStatus(data.services);
        }
    }
    
    updateServiceStatus(services) {
        // Update service status indicators
        services.forEach(service => {
            const element = document.querySelector(`[data-service="${service.name}"]`);
            if (element) {
                const statusSpan = element.querySelector('.px-2.py-1');
                if (service.running) {
                    statusSpan.className = 'px-2 py-1 text-xs font-medium text-green-800 bg-green-100 rounded-full';
                    statusSpan.textContent = 'Running';
                } else {
                    statusSpan.className = 'px-2 py-1 text-xs font-medium text-red-800 bg-red-100 rounded-full';
                    statusSpan.textContent = 'Stopped';
                }
            }
        });
    }
    
    // Charts
    initializeCharts() {
        this.initCpuChart();
        this.initMemoryChart();
    }
    
    initCpuChart() {
        const ctx = document.getElementById('cpuChart');
        if (!ctx) return;
        
        this.charts.cpu = new Chart(ctx, {
            type: 'line',
            data: {
                labels: this.generateTimeLabels(),
                datasets: [{
                    label: 'CPU Usage (%)',
                    data: new Array(24).fill(0),
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: { callback: (value) => `${value}%` }
                    }
                }
            }
        });
    }
    
    initMemoryChart() {
        const ctx = document.getElementById('memoryChart');
        if (!ctx) return;
        
        this.charts.memory = new Chart(ctx, {
            type: 'line',
            data: {
                labels: this.generateTimeLabels(),
                datasets: [{
                    label: 'Memory Usage (%)',
                    data: new Array(24).fill(0),
                    borderColor: '#10b981',
                    backgroundColor: 'rgba(16, 185, 129, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: { callback: (value) => `${value}%` }
                    }
                }
            }
        });
    }
    
    updateChart(chartName, newData) {
        const chart = this.charts[chartName];
        if (chart && newData) {
            chart.data.datasets[0].data.push(newData);
            chart.data.datasets[0].data.shift();
            chart.update();
        }
    }
    
    generateTimeLabels() {
        const labels = [];
        const now = new Date();
        for (let i = 23; i >= 0; i--) {
            const time = new Date(now.getTime() - i * 60 * 60 * 1000);
            labels.push(time.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }));
        }
        return labels;
    }
    
    // Section Data Loading
    loadSectionData(section) {
        switch (section) {
            case 'dashboard':
                this.loadSystemStats();
                break;
            case 'hosting':
                this.loadHostingData();
                break;
            case 'domains':
                this.loadDomainsData();
                break;
            case 'ssl':
                this.loadSSLData();
                break;
            // Add more sections as needed
        }
    }
    
    async loadHostingData() {
        const data = await this.fetchData('/api/hosting/sites');
        if (data && data.success) {
            this.renderHostingTable(data.data);
        }
    }
    
    renderHostingTable(sites) {
        const tbody = document.getElementById('hostingTableBody');
        if (!tbody) return;
        
        tbody.innerHTML = sites.map(site => `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        <div class="text-sm font-medium text-gray-900">${site.domain}</div>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        site.active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }">
                        ${site.active ? 'Ativo' : 'Inativo'}
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    ${site.ssl ? 
                        '<i class="fas fa-shield-alt text-green-500"></i> <span class="text-green-600">Ativo</span>' : 
                        '<i class="fas fa-shield-alt text-gray-400"></i> <span class="text-gray-500">Inativo</span>'
                    }
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    ${site.lastAccess ? new Date(site.lastAccess).toLocaleDateString('pt-BR') : 'N/A'}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button class="text-primary-600 hover:text-primary-900 mr-3" onclick="serverPanel.editSite('${site.id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="text-red-600 hover:text-red-900" onclick="serverPanel.deleteSite('${site.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }
    
    // Utility Methods
    startDataRefresh() {
        // Refresh dashboard data every 30 seconds
        this.refreshInterval = setInterval(() => {
            if (this.currentSection === 'dashboard') {
                this.loadSystemStats();
            }
        }, 30000);
    }
    
    showNotification(notification) {
        // Create notification element
        const notificationEl = document.createElement('div');
        notificationEl.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg max-w-sm transition-all duration-300 ${
            notification.type === 'error' ? 'bg-red-100 text-red-800' :
            notification.type === 'success' ? 'bg-green-100 text-green-800' :
            'bg-blue-100 text-blue-800'
        }`;
        
        notificationEl.innerHTML = `
            <div class="flex items-center">
                <i class="fas fa-${notification.type === 'error' ? 'exclamation-circle' : 
                    notification.type === 'success' ? 'check-circle' : 'info-circle'} mr-2"></i>
                <span>${notification.message}</span>
                <button class="ml-4 text-gray-500 hover:text-gray-700" onclick="this.parentElement.parentElement.remove()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;
        
        document.body.appendChild(notificationEl);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (notificationEl.parentElement) {
                notificationEl.remove();
            }
        }, 5000);
    }
    
    // Mobile sidebar methods
    openSidebar() {
        document.getElementById('sidebar').classList.remove('-translate-x-full');
    }
    
    closeSidebar() {
        document.getElementById('sidebar').classList.add('-translate-x-full');
    }
    
    // Modal Methods
    showAddHostingModal() {
        // Create and show modal for adding new hosting
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 z-50 overflow-y-auto';
        modal.innerHTML = `
            <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
                <div class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" onclick="this.parentElement.parentElement.remove()"></div>
                <div class="inline-block w-full max-w-md p-6 my-8 overflow-hidden text-left align-middle transition-all transform bg-white shadow-xl rounded-2xl">
                    <h3 class="text-lg font-medium leading-6 text-gray-900 mb-4">Adicionar Nova Hospedagem</h3>
                    <form id="addHostingForm">
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Domínio</label>
                            <input type="text" name="domain" required class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500" placeholder="exemplo.com">
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Diretório</label>
                            <input type="text" name="directory" class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500" placeholder="/var/www/exemplo">
                        </div>
                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="php" class="mr-2">
                                <span class="text-sm text-gray-700">Habilitar PHP</span>
                            </label>
                        </div>
                        <div class="mb-6">
                            <label class="flex items-center">
                                <input type="checkbox" name="ssl" class="mr-2">
                                <span class="text-sm text-gray-700">Configurar SSL automaticamente</span>
                            </label>
                        </div>
                        <div class="flex justify-end space-x-3">
                            <button type="button" onclick="this.closest('.fixed').remove()" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200">
                                Cancelar
                            </button>
                            <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-lg hover:bg-primary-700">
                                Criar Site
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        // Handle form submission
        document.getElementById('addHostingForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const data = Object.fromEntries(formData.entries());
            data.php = formData.has('php');
            data.ssl = formData.has('ssl');
            
            const result = await this.createHosting(data);
            if (result.success) {
                modal.remove();
                this.loadHostingData();
                this.showNotification({ type: 'success', message: 'Site criado com sucesso!' });
            } else {
                this.showNotification({ type: 'error', message: result.error });
            }
        });
    }
    
    async createHosting(data) {
        try {
            const response = await fetch('/api/hosting/create', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });
            
            return await response.json();
        } catch (error) {
            return { success: false, error: error.message };
        }
    }
}

// Initialize the panel when DOM is loaded
let serverPanel;
document.addEventListener('DOMContentLoaded', () => {
    serverPanel = new ServerPanel();
});
