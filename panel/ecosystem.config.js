module.exports = {
  apps: [{
    name: 'server-panel',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: 8080
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000,
      SECRET_KEY: process.env.SECRET_KEY || require('crypto').randomBytes(64).toString('hex')
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm Z'
  }],

  deploy: {
    production: {
      user: 'www-data',
      host: 'localhost',
      ref: 'origin/master',
      repo: 'https://github.com/seu-repo/servidor-linux.git',
      path: '/var/www/panel',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
