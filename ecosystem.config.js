module.exports = {
  apps: [
    {
      name: 'directus',
      script: 'npx',
      args: 'directus start',
      instances: process.env.PM2_INSTANCES || 'max',
      exec_mode: process.env.PM2_EXEC_MODE || 'cluster',
      autorestart: process.env.PM2_AUTO_RESTART === 'true',
      watch: false,
      max_memory_restart: process.env.PM2_MAX_MEMORY_RESTART || '1G',
      env: {
        NODE_ENV: 'production',
        PM2_MAX_RESTARTS: parseInt(process.env.PM2_MAX_RESTARTS || '10'),
        PM2_RESTART_DELAY: parseInt(process.env.PM2_RESTART_DELAY || '3000'),
        PM2_KILL_TIMEOUT: parseInt(process.env.PM2_KILL_TIMEOUT || '3000'),
        PM2_LISTEN_TIMEOUT: parseInt(process.env.PM2_LISTEN_TIMEOUT || '10000'),
      },
    },
  ],
};
