# Cross-Dimensional Auto Scaling Guide

This guide details how to implement a high-performance **"Cross Auto Scale"** architecture for Directus, combining **Vertical Scaling** (Docker resource allocation) with **Horizontal Scaling** (Process Clustering via PM2).

It also covers specific handling for scheduled tasks using a decoupled "External Scheduler" pattern.

---

## 1. The Architecture

### Vertical Scaling (Docker)
**"The Bigger House"**
*   **Concept**: Allocating more CPU/RAM capability to a single container.
*   **Role**: Provides the raw infrastructure limits.
*   **Controlled via**: `docker-compose.yml` (`deploy.resources`).

### Horizontal Scaling (PM2 Cluster)
**"More Workers in the House"**
*   **Concept**: Spawning multiple Node.js processes (workers) inside the single container to utilize all available CPU cores.
*   **Role**: Ensures the application actually uses the raw power provided by Docker.
*   **Controlled via**: `ecosystem.config.js` and `.env` (`PM2_INSTANCES`).

---

## 2. Configuration Guide

### Step A: Configure Docker (Vertical)
Define the maximum resources the container is allowed to consume.

**File**: `docker-compose.yml`
```yaml
services:
  directus:
    image: my-directus-image
    deploy:
      resources:
        limits:
          cpus: '4'     # Allocate 4 CPU Cores
          memory: 4G    # Allocate 4GB RAM
```

### Step B: Configure PM2 (Horizontal)
Instruct Directus to fork itself to fill the available capacity.

**File**: `.env`
```bash
# Enable PM2 Process Manager
USE_PM2=true

# "max" auto-detects the 4 CPUs allocated by Docker and creates 4 workers.
PM2_INSTANCES=max

# "cluster" enables load balancing across these workers.
PM2_EXEC_MODE=cluster
```

---

## 3. Critical Concerns & Risks

Combining these scaling methods introduces risks that must be managed.

### Risk 1: Database Connection Exhaustion
Each PM2 worker maintains its **own** pool of database connections.
*   **Scenario**: 4 Workers x `DB_POOL_MAX=10` = **40 Active Connections**.
*   **Failure**: If your Database allows only 20 connections, the app will crash.

**Solution**:
Calculate your pool size dynamically:
```
DB_POOL_MAX = (Max DB Connections / Total Workers) - Safety Margin
```
*Example: If Postgres allows 50 connections and you have 4 workers, set `DB_POOL_MAX=10`.*

### Risk 2: Out of Memory (OOM) Kills
Processes multiply memory usage.
*   **Scenario**: 4 Workers x 600MB each = **2.4GB** RAM required.
*   **Failure**: If Docker limit is set to `2GB`, the OS will kill the container.

**Solution**:
Ensure Docker memory limit > `(PM2_INSTANCES * Max Worker Memory)`.

---

## 4. Advanced Pattern: Decoupled Scheduler

When running multiple workers, internal Cron jobs (Scheduled Flows) can lead to race conditions or duplicate execution (though Redis locks help, they aren't foolproof).

**Best Practice**: Decouple the Scheduler from the Worker.

### Concept
Instead of Directus checking "Is it 9 AM?", an **External Crontab** checks the time and sends a signal to Directus to run the job.

### How to Implement

1.  **In Directus (The Worker)**:
    *   Create a Flow.
    *   **Trigger**: Webhook (`POST`).
    *   **Security**: Add a query parameter check (e.g., `?token=SECRET`).
    *   **Action**: Your job logic (Send Email, Cleanup, etc.).

2.  **External Trigger (The Scheduler)**:
    *   Use the host machine's Crontab, AWS EventBridge, or a separate tiny Docker container.
    *   **Command**:
        ```bash
        # Run at 9:00 AM
        0 9 * * * curl -X POST "http://localhost:8899/flows/trigger/my-flow-id?token=SECRET"
        ```

### Benefits
1.  **Zero Duplication**: The web request hits the Load Balancer (PM2), and exactly **one** worker picks it up.
2.  **Performance**: Your API workers aren't constantly polling for jobs; they only react when told to.
3.  **Stability**: If the scheduler fails, it doesn't crash the API. If the API is busy, the scheduler can retry (if configured).

---

## 5. Summary Checklist

- [ ] **Redis Enabled**: Mandatory for coordination between workers.
- [ ] **DB Pool Calculated**: Adjusted for `PM2_INSTANCES`.
- [ ] **Memory Buffered**: Docker limit comfortably covers all workers.
- [ ] **Logs**: `LOG_STYLE=raw` used to handle interleaved logs.
