# Directus Docker Starter

A production-ready Directus setup using Docker, featuring optional PM2 process management, Redis caching, and external database configuration.

## Features

- **Dockerized**: specific `Dockerfile` extending the official image.
- **PM2 Integration**: Optional process manager for clustering, auto-restarts, and monitoring (`USE_PM2=true`).
- **Production Ready**: Pre-configured with best practices for caching (Redis), logging, rate limiting, and security.
- **External Dependencies**: Designed to connect to existing external Database and Redis services.
- **Advanced Scaling**: See [Cross Auto Scale Guide](CROSS_AUTO_SCALE.md) for Vertical + Horizontal scaling strategies.

## Prerequisites

- __Docker__ and __Docker Compose__ installed.
- **External Database**: PostgreSQL (default), MySQL, or others supported by Directus.
  - *Note*: The database **must exist** before starting. Directus will create the tables, but not the database itself.
- **External Redis Server**: Required for Caching and Rate Limiting.

## Installation & Setup

### 1. Clone & Configure

1.  **Clone the repository** (if applicable) or navigate to your project folder.
2.  **Create configuration file**:
    ```bash
    cp .env.example .env
    ```
3.  **Edit `.env`**:
    Open `.env` and fill in your specific details:
    -   **General**: Set `PUBLIC_URL` and `PORT`.
    -   **Database**: Update `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_DATABASE`.
        -   *Important*: If `DB_HOST` is on your host machine, use the host's IP address (e.g., `192.168.x.x`), not `localhost`.
    -   **Redis**: Update `CACHE_REDIS` and `RATE_LIMITER_REDIS` with your Redis connection string (e.g., `redis://192.168.x.x:6379`).
    -   **PM2**: Set `USE_PM2=true` if you want to use PM2.

### 2. Prepare Database

Log in to your database server and ensure the database exists:
```sql
-- Example for PostgreSQL
CREATE DATABASE directus_starter;
```

### 3. Create Directories

Ensure the local directories for persistence exist:
```bash
mkdir -p uploads extensions
```

### 4. Build and Run

Start the container. Use `--build` to ensure any changes (like toggling PM2) are picked up.

```bash
docker-compose up -d --build
```

You can now access Directus at: **http://localhost:8899** (or the port defined in `.env`).

## PM2 Configuration

This starter allows running Directus with [PM2](https://pm2.keymetrics.io/) for better performance (clustering) and process management.

To enable PM2:
1.  Open `.env`.
2.  Set `USE_PM2=true`.
3.  **Rebuild the container**: `docker-compose up -d --build`.

**PM2 Settings in `.env`**:
-   `PM2_INSTANCES`: Number of instances (default: `max` for all CPU cores).
-   `PM2_EXEC_MODE`: `cluster` (recommended) or `fork`.
-   `PM2_MAX_MEMORY_RESTART`: Restart if memory exceeds limit (e.g., `1G`).
-   `PM2_AUTO_RESTART`, `PM2_RESTART_DELAY`, etc.

## Caching & Performance

This setup is tuned for production performance:
-   **Redis Cache**: Enabled by default. Configured via `CACHE_REDIS`.
-   **Rate Limiting**: Enabled using Redis store (`RATE_LIMITER_REDIS`).
-   **Connection Pooling**: database pool settings (`DB_POOL_MIN`, `DB_POOL_MAX`) are configurable in `.env`.

**Note on Caching**:
Directus **does not cache** requests from the Admin App or authenticated users by default. To test caching, make a public API request:
```bash
curl http://localhost:8899/items/your_collection
```

## Troubleshooting

-   **Container fails to start?**
    Check logs: `docker-compose logs -f`
-   **Database connection error?**
    -   Verify `DB_HOST` is correct and reachable from inside the container.
    -   Verify the database exists (`CREATE DATABASE ...`).
-   **Redis connection error?**
    -   Ensure `CACHE_REDIS` is set to the correct IP/Port.
    -   If using `network_mode: bridge` (default), you cannot use `localhost`. Use your machine's LAN IP.
-   **Port conflict?**
    -   Change `PORT` in `.env` and the port mapping in `docker-compose.yml`.

## File Structure

-   `.env`: Main configuration file.
-   `docker-compose.yml`: Docker service definition.
-   `Dockerfile`: Custom build steps (PM2 installation).
-   `ecosystem.config.js`: PM2 configuration (loads from `.env`).
-   `docker-entrypoint.sh`: Entry script to handle PM2 vs Standard start.
-   `uploads/`: Local mapping for file uploads.
-   `extensions/`: Local mapping for custom extensions.
