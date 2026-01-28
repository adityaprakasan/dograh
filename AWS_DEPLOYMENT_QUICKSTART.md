# Healthline on AWS - Quick Start

Deploy your Healthline voice AI platform to AWS EC2 in 3 steps.

## Prerequisites

- AWS Account
- SSH client (Terminal on Mac/Linux, PowerShell on Windows)

---

## 🚀 Quick Deployment (30 minutes)

### Step 1: Launch EC2 Instance (15 minutes)

**📖 Detailed AWS Console guide: [AWS_CONSOLE_SETUP.md](./AWS_CONSOLE_SETUP.md)**

**Quick steps:**

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2)
2. Click **Launch Instance**
3. Configure:
   - **Name:** `healthline-production`
   - **OS:** Ubuntu Server 24.04 LTS (64-bit x86)
   - **Instance type:** t3.large (2vCPU, 8GB RAM)
   - **Key pair:** Create new (`healthline-key`) - **Download and save!**
   - **Storage:** 30 GB gp3 (50 GB recommended)
   - **Security group rules:** (Create `healthline-sg`)
     - SSH (22) from your IP
     - HTTP (80) from anywhere (0.0.0.0/0)
     - HTTPS (443) from anywhere (0.0.0.0/0)
     - Custom TCP 3010 from anywhere (temporary)
     - Custom TCP 8000 from anywhere (temporary)
4. Click **Launch Instance**
5. Wait ~2-3 minutes for:
   - Instance state: **Running** (green)
   - Status checks: **2/2 passed** (green)
6. **Copy Public IPv4 address** (e.g., 54.123.45.67)
7. **Set key permissions** (Mac/Linux): `chmod 400 ~/Downloads/healthline-key.pem`

### Step 2: Upload Your Code (5 minutes)

**On your local Mac:**

```bash
# Package your Healthline code
cd /Users/aditya/Desktop/dograh
tar -czf healthline.tar.gz \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.env' \
  .

# Upload to EC2 (replace YOUR_IP and YOUR_KEY_PATH)
scp -i ~/Downloads/healthline-key.pem \
    healthline.tar.gz \
    ubuntu@YOUR_EC2_IP:~/

# Also upload the deployment script
scp -i ~/Downloads/healthline-key.pem \
    deploy-to-ec2.sh \
    ubuntu@YOUR_EC2_IP:~/
```

### Step 3: Run Deployment Script (20 minutes)

**SSH into EC2:**
```bash
ssh -i ~/Downloads/healthline-key.pem ubuntu@YOUR_EC2_IP
```

**Extract and deploy:**
```bash
# Extract code
cd ~
mkdir healthline
tar -xzf healthline.tar.gz -C healthline
cd healthline

# Make script executable
chmod +x ~/deploy-to-ec2.sh

# Run deployment script
bash ~/deploy-to-ec2.sh
```

The script will:
- ✅ Install Docker
- ✅ Install Git
- ✅ Configure environment
- ✅ Start all services (API, UI, PostgreSQL, Redis, MinIO)
- ✅ Show you the access URLs

### Step 4: Access Your Application

Once the script completes, open your browser:
```
http://YOUR_EC2_IP:3010
```

**You should see your Healthline dashboard! 🎉**

---

## 📖 Detailed Guide

For complete documentation including:
- Domain setup and HTTPS
- Security hardening
- Monitoring and backups
- Troubleshooting
- Cost optimization

See: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

---

## 🔧 Common Commands

After deployment, SSH into your server and use these commands:

```bash
cd ~/healthline

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop everything
docker compose down

# Start everything
docker compose up -d

# Check status
docker compose ps

# Check resource usage
docker stats
```

---

## 🌐 Setting Up Domain & HTTPS (app.healthlineai.org)

### Option 1: Automated Setup (Recommended) ⭐

**1. Point domain to EC2 IP:**
- Add A record: `app.healthlineai.org` → `YOUR_EC2_IP`
- Wait 5-30 minutes for DNS propagation

**2. Upload and run domain setup script:**
```bash
# On your local Mac
scp -i ~/Downloads/healthline-key.pem \
    setup-domain.sh \
    ubuntu@YOUR_EC2_IP:~/

# On EC2 server
ssh -i ~/Downloads/healthline-key.pem ubuntu@YOUR_EC2_IP
chmod +x setup-domain.sh
bash setup-domain.sh
```

The script will automatically:
- Check DNS configuration
- Install SSL certificate
- Configure nginx reverse proxy
- Update environment variables
- Set up auto-renewal
- Start all services with HTTPS

**3. Access your platform:**
```
https://app.healthlineai.org
```

### Option 2: Manual Setup

See complete guide: [DOMAIN_SETUP_GUIDE.md](./DOMAIN_SETUP_GUIDE.md)

**Quick manual steps:**
```bash
# On EC2
cd ~/healthline
docker compose down
sudo apt install certbot -y
sudo certbot certonly --standalone -d app.healthlineai.org --email your@email.com

mkdir -p certs
sudo cp /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem certs/local.crt
sudo cp /etc/letsencrypt/live/app.healthlineai.org/privkey.pem certs/local.key
sudo chown -R ubuntu:ubuntu certs

cp nginx-healthline.conf nginx.conf

nano .env.production
# Update: BACKEND_API_ENDPOINT=https://app.healthlineai.org
# Update: UI_APP_URL=https://app.healthlineai.org

docker compose --profile remote up -d
```

---

## 💰 Cost Estimate

**Monthly:**
- EC2 t3.large: ~$60
- Storage (30GB): ~$3
- Data transfer: ~$9
- **Total: ~$72/month**

---

## 🆘 Need Help?

1. **Check logs:** `cd ~/healthline && docker compose logs -f`
2. **Check status:** `docker compose ps`
3. **Review full guide:** [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

---

## 📝 Notes

- **Healthline Branding:** Your UI changes (Dograh → Healthline) are included in the code! The branding will show once you build custom Docker images or the images pull your latest code.
- **Security:** For production, follow security hardening steps in the full deployment guide.
- **Scaling:** Start with t3.large, upgrade to t3.xlarge for more traffic.
- **Backups:** Set up regular database backups (instructions in full guide).

---

**Happy Deploying! 🚀**
