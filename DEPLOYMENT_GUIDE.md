# Healthline Voice AI Platform - AWS EC2 Deployment Guide

This guide will help you deploy your Healthline voice AI platform on AWS EC2 with all services (Frontend, Backend, PostgreSQL, Redis, MinIO).

---

## Prerequisites

- AWS Account with billing enabled
- Domain name (optional, for HTTPS)
- SSH key pair for EC2 access

---

## Step 1: Launch EC2 Instance

### 1.1 Go to AWS Console
1. Sign in to [AWS Console](https://console.aws.amazon.com)
2. Navigate to **EC2** service
3. Click **Launch Instance**

### 1.2 Configure Instance
**Name:** `healthline-production`

**Application and OS Images:**
- **OS:** Ubuntu Server 24.04 LTS
- **AMI:** Ubuntu Server 24.04 LTS (HVM), SSD Volume Type

**Instance Type:**
- Select **t3.large** (2 vCPUs, 8GB RAM)
- Good for: 10-50 concurrent users
- Cost: ~$60/month
- For more traffic, use **t3.xlarge** (4 vCPUs, 16GB RAM) at ~$120/month

**Key Pair:**
- Create new key pair or use existing
- **Name:** `healthline-key`
- **Type:** RSA
- **Format:** .pem (for Mac/Linux) or .ppk (for Windows)
- **Download** and save in safe location (you can't download again!)

**Network Settings:**
- Create security group: `healthline-sg`
- Allow SSH from your IP
- Allow HTTP (port 80) from anywhere
- Allow HTTPS (port 443) from anywhere
- Allow custom port 3010 from anywhere (for direct UI access)
- Allow custom port 8000 from anywhere (for direct API access)

**Configure Storage:**
- **Size:** 30 GB minimum (50 GB recommended)
- **Type:** gp3 (General Purpose SSD)

Click **Launch Instance**

---

## Step 2: Connect to Your EC2 Instance

### 2.1 Wait for Instance to Start
Wait ~2 minutes for instance to be in "Running" state with 2/2 status checks passed.

### 2.2 Get Public IP
In EC2 console, note your instance's **Public IPv4 address** (e.g., `54.123.45.67`)

### 2.3 SSH into Instance

**On Mac/Linux:**
```bash
chmod 400 ~/Downloads/healthline-key.pem
ssh -i ~/Downloads/healthline-key.pem ubuntu@54.123.45.67
```

**On Windows (using PowerShell):**
```powershell
ssh -i C:\Users\YourName\Downloads\healthline-key.pem ubuntu@54.123.45.67
```

---

## Step 3: Install Docker and Dependencies

### 3.1 Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### 3.2 Install Docker
```bash
# Add Docker's official GPG key
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Logout and login again for group changes
exit
```

**SSH back in:**
```bash
ssh -i ~/Downloads/healthline-key.pem ubuntu@54.123.45.67
```

**Verify Docker:**
```bash
docker --version
docker compose version
```

### 3.3 Install Git
```bash
sudo apt install git -y
```

---

## Step 4: Deploy Healthline Code

### 4.1 Clone Your Repository

**Option A: If your code is on GitHub:**
```bash
cd ~
git clone https://github.com/your-username/healthline.git
cd healthline
```

**Option B: If deploying from local (since you have renamed code):**

On your **LOCAL MACHINE**, package and upload your code:
```bash
# On your local machine (Mac)
cd /Users/aditya/Desktop/dograh
tar -czf healthline.tar.gz \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.env' \
  .

# Upload to EC2 (replace with your IP and key path)
scp -i ~/Downloads/healthline-key.pem healthline.tar.gz ubuntu@54.123.45.67:~/
```

On **EC2 SERVER**, extract:
```bash
cd ~
mkdir healthline
tar -xzf healthline.tar.gz -C healthline
cd healthline
ls -la  # Verify files are there
```

---

## Step 5: Configure Environment Variables

### 5.1 Get Your Server's Public IP
```bash
# Get public IP
curl -4 ifconfig.me
# Example output: 54.123.45.67
```

### 5.2 Create Environment File for API
```bash
nano .env.production
```

Paste this configuration (replace `YOUR_PUBLIC_IP` with actual IP):
```bash
# Environment
ENVIRONMENT=production
LOG_LEVEL=INFO

# URLs (replace with your EC2 public IP or domain)
BACKEND_API_ENDPOINT=http://YOUR_PUBLIC_IP:8000
UI_APP_URL=http://YOUR_PUBLIC_IP:3010

# Database (using containerized postgres)
DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/postgres

# Redis (using containerized redis)
REDIS_URL=redis://:redissecret@redis:6379

# Storage - using local MinIO
ENABLE_AWS_S3=false
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=voice-audio
MINIO_SECURE=false

# Tracing and Telemetry
ENABLE_TRACING=false
ENABLE_TELEMETRY=false
```

**Save:** Ctrl+O, Enter, Ctrl+X

### 5.3 Update docker-compose.yaml

The existing `docker-compose.yaml` should work, but let's verify the image names are correct:

```bash
nano docker-compose.yaml
```

Make sure these lines use the correct registry (keep as is if using pre-built images):
```yaml
api:
  image: ${REGISTRY:-dograhai}/dograh-api:latest
  
ui:
  image: ${REGISTRY:-dograhai}/dograh-ui:latest
```

**Note:** Since you've renamed to Healthline in the UI code but are using the existing Docker images for now, this will work. The frontend changes are in the source code, not in the current docker images. You'll need to rebuild images later to see your Healthline branding.

---

## Step 6: Deploy the Application

### 6.1 Start All Services
```bash
cd ~/healthline
docker compose up -d --pull always
```

This will:
- Pull all Docker images (API, UI, PostgreSQL, Redis, MinIO, Cloudflare tunnel)
- Start all containers
- Takes 3-5 minutes on first run

### 6.2 Monitor Deployment
```bash
# Watch logs
docker compose logs -f

# Check if all containers are running
docker compose ps

# You should see all services as "Up"
```

### 6.3 Wait for Services to Start
Initial startup takes 2-3 minutes. You'll know it's ready when you see:
```
api-1  | INFO: Uvicorn running on http://0.0.0.0:8000
ui-1   | ▲ Next.js ready on http://0.0.0.0:3010
```

Press `Ctrl+C` to stop watching logs (containers keep running)

---

## Step 7: Access Your Application

### 7.1 Get Your Access URL
```bash
echo "Healthline UI: http://$(curl -s ifconfig.me):3010"
echo "Healthline API: http://$(curl -s ifconfig.me):8000"
```

### 7.2 Open in Browser
Visit the UI URL in your browser (e.g., `http://54.123.45.67:3010`)

You should see the Healthline dashboard! 🎉

---

## Step 8: Set Up Domain and HTTPS (Optional but Recommended)

### 8.1 Point Domain to EC2
In your domain registrar (Namecheap, GoDaddy, Cloudflare, etc.):

1. Add an **A Record**:
   - **Name:** `@` (for root) or `app` (for subdomain)
   - **Value:** Your EC2 public IP (e.g., `54.123.45.67`)
   - **TTL:** 300 seconds

2. Wait 5-30 minutes for DNS propagation

3. Verify:
   ```bash
   nslookup yourdomain.com
   ```

### 8.2 Install and Configure SSL (Let's Encrypt)

**On EC2 Server:**

```bash
# Install Certbot
sudo apt install certbot -y

# Stop services temporarily
cd ~/healthline
docker compose --profile remote down

# Generate SSL certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Create certs directory
mkdir -p ~/healthline/certs

# Copy certificates
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ~/healthline/certs/local.crt
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ~/healthline/certs/local.key
sudo chown -R ubuntu:ubuntu ~/healthline/certs
chmod 644 ~/healthline/certs/*
```

### 8.3 Update nginx Configuration

```bash
cd ~/healthline
nano nginx.conf
```

Update the `server_name` line:
```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com www.yourdomain.com;  # Change this
    
    ssl_certificate     /etc/nginx/certs/local.crt;
    ssl_certificate_key /etc/nginx/certs/local.key;
    
    # ... rest stays the same
}
```

### 8.4 Update Environment Variables

```bash
nano .env.production
```

Update URLs to use your domain:
```bash
BACKEND_API_ENDPOINT=https://yourdomain.com
UI_APP_URL=https://yourdomain.com
```

### 8.5 Restart with HTTPS

```bash
# Start with remote profile (includes nginx)
docker compose --profile remote up -d

# Check logs
docker compose logs nginx
```

### 8.6 Access via HTTPS
Visit: `https://yourdomain.com`

### 8.7 Set Up Auto-Renewal

```bash
# Create renewal script
sudo nano /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh
```

Paste:
```bash
#!/bin/bash
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /home/ubuntu/healthline/certs/local.crt
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /home/ubuntu/healthline/certs/local.key
chmod 644 /home/ubuntu/healthline/certs/*
cd /home/ubuntu/healthline
docker compose --profile remote restart nginx
```

Make executable:
```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh

# Test renewal
sudo certbot renew --dry-run
```

---

## Step 9: Build Custom Docker Images (Optional - For Healthline Branding)

Since you renamed everything to Healthline, you'll eventually want to build custom images:

### 9.1 Build and Push Images

**On EC2 or Your Local Machine:**

```bash
cd ~/healthline

# Build API image
docker build -f api/Dockerfile -t yourdockerhub/healthline-api:latest .

# Build UI image  
docker build -f ui/Dockerfile -t yourdockerhub/healthline-ui:latest .

# Push to Docker Hub (if you have account)
docker login
docker push yourdockerhub/healthline-api:latest
docker push yourdockerhub/healthline-ui:latest
```

### 9.2 Update docker-compose.yaml

```bash
nano docker-compose.yaml
```

Change image names:
```yaml
api:
  image: yourdockerhub/healthline-api:latest
  
ui:
  image: yourdockerhub/healthline-ui:latest
```

### 9.3 Restart with New Images

```bash
docker compose down
docker compose up -d
```

---

## Common Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api
docker compose logs -f ui
```

### Restart Services
```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart api
docker compose restart ui
```

### Stop Services
```bash
docker compose down
```

### Start Services
```bash
docker compose up -d
```

### Update to Latest Version
```bash
cd ~/healthline
git pull  # If using git
docker compose pull
docker compose up -d
```

### Check Resource Usage
```bash
docker stats
```

### Access Database
```bash
docker compose exec postgres psql -U postgres
```

### Access Redis
```bash
docker compose exec redis redis-cli -a redissecret
```

---

## Monitoring and Maintenance

### Check Disk Space
```bash
df -h
```

### Clean Up Old Docker Images
```bash
docker system prune -a
```

### View Running Containers
```bash
docker ps
```

### Database Backup
```bash
docker compose exec postgres pg_dump -U postgres postgres > backup_$(date +%Y%m%d).sql
```

---

## Troubleshooting

### Services Won't Start
```bash
# Check logs
docker compose logs

# Check if ports are in use
sudo netstat -tulpn | grep -E ':(3010|8000|5432|6379)'

# Restart Docker
sudo systemctl restart docker
```

### Out of Disk Space
```bash
# Check space
df -h

# Clean Docker
docker system prune -a -f

# Check what's using space
du -sh /var/lib/docker/*
```

### Can't Connect to UI
1. Check security group allows port 3010
2. Check container is running: `docker ps`
3. Check logs: `docker compose logs ui`
4. Try from EC2: `curl localhost:3010`

### Database Connection Issues
```bash
# Check if postgres is running
docker compose ps postgres

# Check logs
docker compose logs postgres

# Test connection
docker compose exec api python -c "from db import engine; print('Connected!')"
```

---

## Security Hardening (Recommended)

### 1. Update Security Group
- Remove direct access to ports 3010 and 8000
- Only allow 80 and 443 (route through nginx)

### 2. Change Default Passwords
```bash
nano docker-compose.yaml
```

Change:
- Postgres password (POSTGRES_PASSWORD)
- Redis password (requirepass)
- MinIO credentials (MINIO_ROOT_USER, MINIO_ROOT_PASSWORD)

### 3. Enable Firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 4. Regular Updates
```bash
# Set up automatic security updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## Cost Estimation

**Monthly AWS Costs:**
- EC2 t3.large (2vCPU, 8GB): ~$60
- EBS Storage (30GB): ~$3
- Data Transfer (100GB): ~$9
- **Total: ~$72/month**

**Scaling Up (t3.xlarge for more traffic):**
- EC2 t3.xlarge (4vCPU, 16GB): ~$120
- EBS Storage (50GB): ~$5
- Data Transfer (200GB): ~$18
- **Total: ~$143/month**

---

## Next Steps

1. ✅ Deploy application
2. ✅ Configure domain and HTTPS
3. 🔄 Build custom Docker images with Healthline branding
4. 📊 Set up monitoring (AWS CloudWatch, Datadog, etc.)
5. 🔐 Configure backup strategy
6. 📈 Set up auto-scaling (if needed)

---

## Support

If you encounter issues:
1. Check logs: `docker compose logs`
2. Check container status: `docker ps`
3. Check EC2 instance: `top`, `df -h`, `free -m`
4. Review security groups in AWS console

---

**Congratulations! Your Healthline Voice AI Platform is now live on AWS! 🎉**
