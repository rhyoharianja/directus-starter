FROM directus/directus:latest

USER root

# Install PM2 globally conditionally
ARG USE_PM2=false
RUN if [ "$USE_PM2" = "true" ]; then \
  npm install -g pm2; \
  fi

USER node

# Copy PM2 config
COPY ecosystem.config.js .

# Copy custom entrypoint
COPY docker-entrypoint.sh .

# Ensure entrypoint is executable (if copied from Windows/etc, but good practice)
USER root
RUN chmod +x docker-entrypoint.sh
USER node

ENTRYPOINT ["./docker-entrypoint.sh"]
