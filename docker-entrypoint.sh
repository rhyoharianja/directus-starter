#!/bin/sh

set -e

# Run migrations (Directus standard behavior)
# We can rely on the base image's entrypoint or run it manually if we override it completely.
# The base image entrypoint usually does `npx directus bootstrap` or similar if needed.
# Let's try to preserve the original behavior or at least bootstrap.
# Since we are overriding the entrypoint/cmd, we should ensure bootstrap happens.

echo "Running Directus Bootstrap..."
npx directus bootstrap

if [ "$USE_PM2" = "true" ]; then
    echo "Starting Directus with PM2..."
    exec pm2-runtime start ecosystem.config.js
else
    echo "Starting Directus with standard command..."
    exec npx directus start
fi
