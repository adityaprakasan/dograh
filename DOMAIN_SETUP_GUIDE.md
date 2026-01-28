# Setting Up app.healthlineai.org with Nginx Reverse Proxy

This guide will help you configure your Healthline platform to be accessible at `https://app.healthlineai.org` with proper SSL and nginx reverse proxy.

---

## Prerequisites

- EC2 instance running with Healthline deployed
- Access to your domain registrar (where healthlineai.org is registered)
- SSH access to your EC2 instance

---

## Step 1: Configure DNS (5 minutes)

### 1.1 Get Your EC2 Public IP

**On your EC2 instance:**
```bash
curl -4 ifconfig.me
```

Copy this IP address (e.g., `54.123.45.67`)

### 1.2 Add DNS A Record

Go to your domain registrar (GoDaddy, Namecheap, Cloudflare, etc.) and add:

**A Record:**
- **Type:** A
- **Name:** `app` (or `app.healthlineai.org` depending on your registrar)
- **Value/Points to:** Your EC2 IP (e.g., `54.123.45.67`)
- **TTL:** 300 seconds (5 minutes) or Auto

**Save** the DNS record.

### 1.3 Verify DNS Propagation

Wait 5-10 minutes, then check:

```bash
# On your local machine
nslookup app.healthlineai.org

# Or use online tool
# Visit: https://dnschecker.org/#A/app.healthlineai.org
```

You should see your EC2 IP address in the results.

---

## Step 2: Install SSL Certificate (10 minutes)

### 2.1 SSH into EC2

```bash
ssh -i ~/Downloads/your-key.pem ubuntu@YOUR_EC2_IP
```

### 2.2 Stop Current Services

```bash
cd ~/healthline
docker compose down
```

### 2.3 Install Certbot

```bash
sudo apt update
sudo apt install certbot -y
```

### 2.4 Generate SSL Certificate

```bash
sudo certbot certonly --standalone \
  -d app.healthlineai.org \
  --non-interactive \
  --agree-tos \
  --email your-email@example.com
```

**Replace `your-email@example.com` with your actual email.**

You should see:
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/app.healthlineai.org/privkey.pem
```

### 2.5 Copy Certificates to Project

```bash
cd ~/healthline
mkdir -p certs

sudo cp /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem certs/local.crt
sudo cp /etc/letsencrypt/live/app.healthlineai.org/privkey.pem certs/local.key

sudo chown -R ubuntu:ubuntu certs
chmod 644 certs/*
```

---

## Step 3: Configure Nginx (5 minutes)

### 3.1 Backup Original Config

```bash
cd ~/healthline
cp nginx.conf nginx.conf.backup
```

### 3.2 Use New Nginx Configuration

The new nginx configuration is already in your project: `nginx-healthline.conf`

```bash
# Copy the new config to replace the old one
cp nginx-healthline.conf nginx.conf
```

### 3.3 Verify Nginx Config

```bash
cat nginx.conf | grep server_name
```

You should see: `server_name app.healthlineai.org;`

---

## Step 4: Update Environment Variables (5 minutes)

### 4.1 Update API Environment

```bash
cd ~/healthline
nano .env.production
```

**Update these lines:**
```bash
# URLs - Update to use your domain
BACKEND_API_ENDPOINT=https://app.healthlineai.org
UI_APP_URL=https://app.healthlineai.org

# Everything else stays the same
ENVIRONMENT=production
LOG_LEVEL=INFO
DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/postgres
REDIS_URL=redis://:redissecret@redis:6379
ENABLE_AWS_S3=false
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=voice-audio
MINIO_SECURE=false
ENABLE_TRACING=false
ENABLE_TELEMETRY=false
```

**Save:** Ctrl+O, Enter, Ctrl+X

### 4.2 Update UI Environment (if needed)

If you have a `ui/.env` or `ui/.env.production`, update it:

```bash
nano ui/.env.production
```

Add/update:
```bash
NEXT_PUBLIC_API_BASE_URL=https://app.healthlineai.org
```

---

## Step 5: Update Docker Compose for Remote Deployment (5 minutes)

### 5.1 Edit docker-compose.yaml

```bash
nano docker-compose.yaml
```

Make sure the `nginx` service exists and uses the `remote` profile. It should look like:

```yaml
nginx:
  image: nginx:alpine
  profiles:
    - remote
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    - ./certs:/etc/nginx/certs:ro
  depends_on:
    - api
    - ui
  networks:
    - app-network
  restart: unless-stopped
```

**Save:** Ctrl+O, Enter, Ctrl+X

---

## Step 6: Start Services with Nginx (5 minutes)

### 6.1 Start Everything

```bash
cd ~/healthline

# Start with the 'remote' profile to include nginx
docker compose --profile remote up -d
```

### 6.2 Check Status

```bash
docker compose ps
```

You should see:
- ✅ postgres - Up
- ✅ redis - Up
- ✅ minio - Up
- ✅ api - Up
- ✅ ui - Up
- ✅ nginx - Up
- ✅ cloudflared - Up (if using)

### 6.3 Monitor Logs

```bash
docker compose logs -f nginx api ui
```

Wait until you see:
```
api-1    | INFO: Uvicorn running on http://0.0.0.0:8000
ui-1     | ▲ Next.js ready on http://0.0.0.0:3010
nginx-1  | /docker-entrypoint.sh: Configuration complete; ready for start up
```

Press `Ctrl+C` to stop watching logs (containers keep running)

---

## Step 7: Update Security Group (2 minutes)

### 7.1 Remove Direct Access to Ports

Since nginx is now handling all traffic, you should update your EC2 security group:

**Remove/Restrict:**
- Port 3010 (UI direct access - no longer needed)
- Port 8000 (API direct access - no longer needed)

**Keep:**
- Port 22 (SSH)
- Port 80 (HTTP - nginx will redirect to HTTPS)
- Port 443 (HTTPS - nginx handles this)

**To update:**
1. Go to AWS EC2 Console
2. Find your instance
3. Click on the Security Group
4. Edit Inbound Rules
5. Remove rules for ports 3010 and 8000

---

## Step 8: Test Your Deployment (5 minutes)

### 8.1 Test HTTPS Access

Open your browser and visit:
```
https://app.healthlineai.org
```

You should see:
- ✅ Healthline dashboard loads
- ✅ Green padlock icon (valid SSL)
- ✅ No certificate warnings

### 8.2 Test HTTP Redirect

Visit:
```
http://app.healthlineai.org
```

It should automatically redirect to `https://app.healthlineai.org`

### 8.3 Test API Access

```bash
curl https://app.healthlineai.org/health
```

Should return API health status.

### 8.4 Test from EC2 Server

```bash
# SSH into your EC2
ssh -i ~/Downloads/your-key.pem ubuntu@YOUR_EC2_IP

# Test internal routing
curl http://localhost/health
curl http://localhost:3010
curl http://localhost:8000/health

# Test external access
curl https://app.healthlineai.org
curl https://app.healthlineai.org/api/v1/health
```

---

## Step 9: Set Up SSL Auto-Renewal (5 minutes)

Let's Encrypt certificates expire every 90 days. Set up automatic renewal:

### 9.1 Create Renewal Hook Script

```bash
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo nano /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh
```

Paste:
```bash
#!/bin/bash
# Copy new certificates to Healthline project
cp /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem /home/ubuntu/healthline/certs/local.crt
cp /etc/letsencrypt/live/app.healthlineai.org/privkey.pem /home/ubuntu/healthline/certs/local.key
chmod 644 /home/ubuntu/healthline/certs/*

# Reload nginx
cd /home/ubuntu/healthline
docker compose --profile remote restart nginx

echo "SSL certificates updated and nginx reloaded - $(date)" >> /var/log/healthline-ssl-renewal.log
```

**Save:** Ctrl+O, Enter, Ctrl+X

### 9.2 Make Script Executable

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh
```

### 9.3 Test Renewal Process

```bash
sudo certbot renew --dry-run
```

You should see: `Congratulations, all simulated renewals succeeded`

### 9.4 Verify Auto-Renewal is Enabled

Certbot installs a systemd timer that runs twice daily. Check it:

```bash
sudo systemctl status certbot.timer
```

Should show: `Active: active (waiting)`

---

## Step 10: Verify Everything Works (5 minutes)

### ✅ Checklist

Run through this checklist:

**DNS & SSL:**
- [ ] `https://app.healthlineai.org` loads without certificate errors
- [ ] `http://app.healthlineai.org` redirects to HTTPS
- [ ] Browser shows green padlock icon
- [ ] Certificate is valid and issued by Let's Encrypt

**Application:**
- [ ] Healthline dashboard loads and displays correctly
- [ ] Can log in / sign up (if auth is set up)
- [ ] All UI features work (workflows, agents, etc.)
- [ ] No console errors in browser dev tools

**API:**
- [ ] `https://app.healthlineai.org/api/v1/health` returns 200 OK
- [ ] `https://app.healthlineai.org/docs` shows API documentation
- [ ] API calls from UI work correctly

**Services:**
- [ ] All Docker containers running: `docker compose ps`
- [ ] No errors in logs: `docker compose logs`
- [ ] Database accessible: `docker compose exec postgres psql -U postgres -c "SELECT 1"`
- [ ] Redis accessible: `docker compose exec redis redis-cli -a redissecret PING`

---

## Troubleshooting

### Problem: DNS not resolving

**Solution:**
```bash
# Check DNS propagation
nslookup app.healthlineai.org

# If still not working, wait 30 minutes for DNS to propagate globally
# You can check propagation at: https://dnschecker.org
```

### Problem: SSL certificate error

**Solution:**
```bash
# Check certificate files exist
ls -la ~/healthline/certs/

# Should see local.crt and local.key

# If missing, regenerate:
cd ~/healthline
docker compose --profile remote down
sudo certbot certonly --standalone -d app.healthlineai.org --force-renewal
sudo cp /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem certs/local.crt
sudo cp /etc/letsencrypt/live/app.healthlineai.org/privkey.pem certs/local.key
sudo chown -R ubuntu:ubuntu certs
docker compose --profile remote up -d
```

### Problem: "502 Bad Gateway" error

**Solution:**
```bash
# Check if backend services are running
docker compose ps

# Check nginx logs
docker compose logs nginx

# Check API logs
docker compose logs api

# Check UI logs
docker compose logs ui

# Restart all services
docker compose --profile remote restart
```

### Problem: Nginx won't start

**Solution:**
```bash
# Check nginx configuration syntax
docker run --rm -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx:alpine nginx -t

# Check nginx logs
docker compose logs nginx

# Common issues:
# - Certificate files missing in certs/
# - Wrong server_name in nginx.conf
# - Port 80 or 443 already in use
```

### Problem: Can't connect to API from UI

**Solution:**
```bash
# Check environment variables
cat .env.production | grep URL

# Should show:
# BACKEND_API_ENDPOINT=https://app.healthlineai.org
# UI_APP_URL=https://app.healthlineai.org

# If wrong, update and restart:
nano .env.production
docker compose --profile remote restart api ui
```

### Problem: WebSocket connections failing

**Solution:**
```bash
# Check nginx.conf has websocket support
grep -A5 "Upgrade" nginx.conf

# Should see:
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";

# If missing, update nginx.conf and restart
docker compose --profile remote restart nginx
```

---

## Useful Commands

### View Logs
```bash
cd ~/healthline

# All services
docker compose logs -f

# Nginx only
docker compose logs -f nginx

# API only
docker compose logs -f api

# UI only
docker compose logs -f ui
```

### Restart Services
```bash
# Restart nginx
docker compose --profile remote restart nginx

# Restart API
docker compose restart api

# Restart UI
docker compose restart ui

# Restart everything
docker compose --profile remote restart
```

### Stop/Start
```bash
# Stop everything
docker compose --profile remote down

# Start everything
docker compose --profile remote up -d
```

### Check SSL Certificate Expiry
```bash
sudo certbot certificates
```

### Force SSL Renewal
```bash
sudo certbot renew --force-renewal
sudo /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh
```

### Test Nginx Config
```bash
docker compose --profile remote exec nginx nginx -t
```

---

## Architecture Overview

After setup, your architecture looks like this:

```
Internet
    ↓
[Port 80/443] - HTTPS/SSL
    ↓
AWS EC2 Security Group
    ↓
Nginx Reverse Proxy (Container)
    ↓
    ├─→ UI (Next.js) - Port 3010 (Internal)
    │   - Serves: /
    │   - All frontend routes
    │
    └─→ API (FastAPI) - Port 8000 (Internal)
        - Serves: /api/*
        - Serves: /docs, /openapi.json
        │
        ├─→ PostgreSQL - Port 5432 (Internal)
        ├─→ Redis - Port 6379 (Internal)
        └─→ MinIO - Port 9000 (Internal)
```

**Key Points:**
- Only ports 80 and 443 are publicly accessible
- All internal services communicate via Docker network
- Nginx handles SSL termination
- Nginx routes requests to appropriate services
- All traffic is encrypted (HTTPS)

---

## Next Steps

1. ✅ Set up monitoring (CloudWatch, Datadog, etc.)
2. ✅ Configure backups for PostgreSQL
3. ✅ Set up log aggregation
4. ✅ Configure CDN (CloudFront) for static assets (optional)
5. ✅ Set up WAF (Web Application Firewall) for additional security (optional)
6. ✅ Create staging environment (optional)

---

## 🎉 Congratulations!

Your Healthline Voice AI platform is now live at:

**https://app.healthlineai.org**

With:
- ✅ SSL/HTTPS encryption
- ✅ Nginx reverse proxy
- ✅ Auto-renewing certificates
- ✅ Professional domain
- ✅ All Healthline branding

**Your platform is production-ready!** 🚀
