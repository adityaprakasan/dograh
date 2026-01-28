# 🎉 Healthline Platform - Ready to Deploy!

Your Healthline voice AI platform (renamed from Dograh) is ready for AWS EC2 deployment with the domain **app.healthlineai.org**.

---

## ✅ What's Been Done

### 1. Complete Rebranding: Dograh → Healthline
All frontend code has been updated:
- User-facing text and labels
- Cookie and storage keys
- Widget names and IDs
- API token field names
- Domain references
- Application title and metadata

### 2. Deployment Infrastructure Created
Complete AWS EC2 deployment setup with:
- Docker Compose orchestration
- Nginx reverse proxy configuration
- SSL/HTTPS setup with Let's Encrypt
- Environment configuration templates
- Automated deployment scripts

### 3. Domain Configuration Ready
Pre-configured for **app.healthlineai.org**:
- Custom nginx configuration (`nginx-healthline.conf`)
- SSL certificate setup
- Automatic HTTP → HTTPS redirect
- WebSocket support for real-time features

---

## 📁 Files You Have

### 🚀 Quick Start Guides
1. **`QUICK_REFERENCE.md`** - One-page cheat sheet ⭐ **START HERE**
2. **`DEPLOYMENT_SUMMARY.md`** - Overview and checklist
3. **`AWS_DEPLOYMENT_QUICKSTART.md`** - 30-minute deployment

### 📖 Detailed Guides
4. **`DEPLOYMENT_GUIDE.md`** - Complete 60-minute walkthrough
5. **`DOMAIN_SETUP_GUIDE.md`** - Domain & HTTPS setup for app.healthlineai.org

### 🤖 Automated Scripts
6. **`deploy-to-ec2.sh`** - Initial deployment automation
7. **`setup-domain.sh`** - Domain setup automation ⭐

### ⚙️ Configuration Files
8. **`nginx-healthline.conf`** - Nginx reverse proxy config
9. **`.dockerignore`** - Docker build optimization
10. **`docker-compose.yaml`** - Service orchestration

---

## 🚀 Deployment Path (Choose One)

### Path 1: Fully Automated (Easiest) ⭐
**Time: ~45 minutes**

**Use: `QUICK_REFERENCE.md` + Automated Scripts**

1. Launch EC2 instance
2. Set DNS: `app.healthlineai.org` → EC2 IP
3. Upload code and run `deploy-to-ec2.sh`
4. Run `setup-domain.sh`
5. Done! Access at `https://app.healthlineai.org`

### Path 2: Quick Manual (Learning) 
**Time: ~60 minutes**

**Use: `AWS_DEPLOYMENT_QUICKSTART.md`**

Step-by-step manual deployment with explanations. Good for understanding what's happening.

### Path 3: Complete Manual (Deep Learning)
**Time: ~90 minutes**

**Use: `DEPLOYMENT_GUIDE.md` + `DOMAIN_SETUP_GUIDE.md`**

Full detailed walkthrough with security hardening, monitoring setup, and production best practices.

---

## ⚡ Super Quick Deployment (TL;DR)

### Prerequisites
- AWS account
- Domain registrar access (for healthlineai.org)
- SSH key pair

### Steps

**1. Launch EC2**
```
- Ubuntu 24.04 LTS
- t3.large (2vCPU, 8GB)
- 30GB storage
- Ports: 22, 80, 443
```

**2. Set DNS**
```
A record: app → YOUR_EC2_IP
Domain: healthlineai.org
```

**3. Deploy** (on your Mac)
```bash
cd /Users/aditya/Desktop/dograh
tar -czf healthline.tar.gz --exclude='.git' --exclude='node_modules' .
scp -i ~/key.pem healthline.tar.gz ubuntu@YOUR_IP:~/
scp -i ~/key.pem deploy-to-ec2.sh ubuntu@YOUR_IP:~/
scp -i ~/key.pem setup-domain.sh ubuntu@YOUR_IP:~/
```

**4. Setup** (on EC2)
```bash
ssh -i ~/key.pem ubuntu@YOUR_IP
mkdir healthline && tar -xzf healthline.tar.gz -C healthline
chmod +x *.sh
bash deploy-to-ec2.sh       # Initial deployment (~15 min)
bash setup-domain.sh         # Domain & SSL setup (~10 min)
```

**5. Access**
```
https://app.healthlineai.org
```

**Done! 🎉**

---

## 📊 What You Get

### Services Running
- ✅ **Frontend (Next.js)** - Healthline UI on port 3010
- ✅ **Backend (FastAPI)** - API on port 8000
- ✅ **PostgreSQL** - Database on port 5432
- ✅ **Redis** - Cache/Queue on port 6379
- ✅ **MinIO** - S3-compatible storage on port 9000
- ✅ **Nginx** - Reverse proxy on ports 80/443
- ✅ **Cloudflare Tunnel** - For webhooks

### Architecture
```
Internet (HTTPS)
    ↓
app.healthlineai.org
    ↓
Nginx (SSL termination)
    ├─→ / → UI (Next.js)
    └─→ /api/* → API (FastAPI)
         ├─→ PostgreSQL
         ├─→ Redis
         └─→ MinIO
```

### Features Working
- Voice AI agents
- Workflow builder
- Real-time transcription
- Telephony integration
- Campaign management
- WebRTC calls
- Usage tracking
- All Healthline branding

---

## 💰 Cost Estimate

### t3.large (Recommended to Start)
- **vCPUs:** 2
- **RAM:** 8GB
- **Users:** 10-50 concurrent
- **Cost:** ~$72/month
  - EC2: $60
  - Storage: $3
  - Transfer: $9

### t3.xlarge (For Growth)
- **vCPUs:** 4
- **RAM:** 16GB
- **Users:** 50-200 concurrent
- **Cost:** ~$143/month
  - EC2: $120
  - Storage: $5
  - Transfer: $18

---

## 🔧 Common Commands

### After Deployment

```bash
# SSH into server
ssh -i ~/Downloads/healthline-key.pem ubuntu@YOUR_EC2_IP

# Check status
cd ~/healthline
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose --profile remote restart

# Check SSL certificate
sudo certbot certificates
```

### Maintenance

```bash
# Update application
cd ~/healthline
git pull  # If using git
docker compose pull
docker compose --profile remote up -d

# Backup database
docker compose exec postgres pg_dump -U postgres > backup.sql

# Check disk space
df -h

# Clean up Docker
docker system prune -a -f
```

---

## 🆘 Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| DNS not resolving | Wait 30 min, verify A record |
| 502 Bad Gateway | `docker compose --profile remote restart` |
| SSL certificate error | Re-run `setup-domain.sh` |
| Out of memory | Upgrade to t3.xlarge |
| Can't access site | Check security group ports 80/443 |
| Service won't start | Check logs: `docker compose logs <service>` |

**Detailed troubleshooting:** See `DOMAIN_SETUP_GUIDE.md`

---

## ✅ Deployment Checklist

### Before You Start
- [ ] AWS account created and billing enabled
- [ ] Domain `healthlineai.org` owned and accessible
- [ ] SSH key pair downloaded
- [ ] Email ready for SSL certificate

### EC2 Setup
- [ ] Instance launched (Ubuntu 24.04, t3.large)
- [ ] Security group configured (ports 22, 80, 443)
- [ ] SSH connection tested
- [ ] Public IP noted

### DNS Configuration
- [ ] A record created: `app.healthlineai.org` → EC2 IP
- [ ] DNS propagation verified (5-30 min wait)

### Deployment
- [ ] Code uploaded to EC2
- [ ] `deploy-to-ec2.sh` executed successfully
- [ ] All containers running
- [ ] Basic HTTP access working

### Domain & HTTPS
- [ ] `setup-domain.sh` executed successfully
- [ ] SSL certificate generated
- [ ] Nginx reverse proxy configured
- [ ] HTTPS access working
- [ ] HTTP redirects to HTTPS
- [ ] Auto-renewal configured

### Verification
- [ ] `https://app.healthlineai.org` loads
- [ ] Green padlock visible (valid SSL)
- [ ] Healthline branding visible
- [ ] Can log in / navigate UI
- [ ] API responding (`/api/v1/health`)
- [ ] No console errors

### Security
- [ ] Security group locked down (removed 3010, 8000)
- [ ] Default passwords changed
- [ ] Firewall enabled
- [ ] Auto-updates configured

### Production Ready
- [ ] Backups configured
- [ ] Monitoring set up
- [ ] Documentation reviewed
- [ ] Team trained on maintenance commands

---

## 🎓 Learning Resources

### Your Documentation
- **Quick Start**: `QUICK_REFERENCE.md`
- **AWS Deployment**: `AWS_DEPLOYMENT_QUICKSTART.md`
- **Domain Setup**: `DOMAIN_SETUP_GUIDE.md`
- **Complete Guide**: `DEPLOYMENT_GUIDE.md`

### External Resources
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt Guide](https://letsencrypt.org/getting-started/)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

## 🔒 Security Best Practices

### Immediate (Do Before Going Live)
1. Change default passwords in `docker-compose.yaml`
2. Lock down security group (only 22, 80, 443)
3. Generate SSL certificate for HTTPS
4. Enable Ubuntu firewall (`ufw`)

### Within First Week
1. Set up automated backups
2. Configure monitoring (CloudWatch/Datadog)
3. Enable auto-security updates
4. Review and rotate credentials
5. Set up log aggregation

### Ongoing
1. Monitor disk space weekly
2. Review logs for suspicious activity
3. Test backup restoration monthly
4. Update dependencies monthly
5. Review AWS costs monthly

---

## 📈 Scaling Guide

### When to Scale Up

**Move to t3.xlarge when:**
- CPU consistently > 70%
- Memory consistently > 80%
- Response times increasing
- 50+ concurrent users

**Check metrics:**
```bash
docker stats  # CPU/Memory usage
df -h         # Disk space
free -m       # Memory details
top           # Overall system
```

### How to Scale Up

**Vertical Scaling (Bigger Instance):**
1. Stop application: `docker compose down`
2. Create AMI of current instance
3. Launch new t3.xlarge from AMI
4. Update DNS to new IP
5. Start application: `docker compose --profile remote up -d`

**Horizontal Scaling (Multiple Instances):**
- Set up AWS ECS/EKS
- Use RDS for PostgreSQL
- Use ElastiCache for Redis
- Use S3 for MinIO
- Add load balancer

---

## 🎯 Next Steps After Deployment

### Immediate
1. Test all features thoroughly
2. Create test workflow
3. Make test voice call
4. Verify webhooks working

### First Week
1. Set up monitoring and alerts
2. Configure automated backups
3. Document any custom configuration
4. Train team on platform

### First Month
1. Analyze usage patterns
2. Optimize based on metrics
3. Plan for scaling if needed
4. Review and refine workflows

---

## 💡 Pro Tips

1. **Always use `--profile remote`** when nginx is needed
2. **Keep a backup** of working configuration files
3. **Test SSL renewal** before it expires
4. **Monitor logs daily** for first week
5. **Document custom changes** you make
6. **Use tmux/screen** for long-running commands
7. **Keep a runbook** of your specific setup

---

## 🎉 You're Ready to Deploy!

Everything is prepared for your AWS deployment:
- ✅ Code renamed to Healthline
- ✅ Docker configuration ready
- ✅ Nginx reverse proxy configured
- ✅ Domain setup prepared (app.healthlineai.org)
- ✅ Automated scripts created
- ✅ Comprehensive documentation written

### Recommended Next Action:

**Open `QUICK_REFERENCE.md` and follow the Super Quick Deployment section!**

Or if you prefer detailed guidance:
1. Start with `AWS_DEPLOYMENT_QUICKSTART.md` for initial deployment
2. Then follow `DOMAIN_SETUP_GUIDE.md` for domain setup

**Your platform will be live at `https://app.healthlineai.org` in less than 1 hour!** 🚀

---

## 📞 Need Help?

1. **Check logs first**: `docker compose logs -f`
2. **Review troubleshooting**: See relevant guide's troubleshooting section
3. **Search error message**: Often others have solved similar issues
4. **Check AWS status**: Sometimes it's an AWS issue

**Most issues are solved by:**
- Restarting services: `docker compose --profile remote restart`
- Checking security groups
- Verifying DNS settings
- Reviewing logs for specific error messages

---

**Good luck with your deployment! You've got this!** 💪
