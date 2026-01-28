# 🚀 Healthline Deployment - Quick Reference Card

## 📋 What You Need

- [ ] AWS Account
- [ ] Domain: `healthlineai.org` (configured DNS)
- [ ] SSH key for EC2
- [ ] Email for SSL certificate

---

## ⚡ Super Quick Deployment

### 1. Launch EC2 (15 min)
**📖 See:** [AWS_CONSOLE_SETUP.md](./AWS_CONSOLE_SETUP.md) for detailed steps
- Ubuntu 24.04 LTS, t3.large, 30GB
- Security group: 22, 80, 443, 3010, 8000
- Create & download key: `healthline-key.pem`
- Copy Public IPv4 IP

### 2. Set DNS (2 min)
- A record: `app.healthlineai.org` → EC2 IP
- Wait 5-10 min

### 3. Upload & Deploy (25 min)
```bash
# Local Mac
cd /Users/aditya/Desktop/dograh
tar -czf healthline.tar.gz --exclude='.git' --exclude='node_modules' .
scp -i ~/Downloads/healthline-key.pem healthline.tar.gz ubuntu@YOUR_IP:~/
scp -i ~/Downloads/healthline-key.pem deploy-to-ec2.sh ubuntu@YOUR_IP:~/
scp -i ~/Downloads/healthline-key.pem setup-domain.sh ubuntu@YOUR_IP:~/

# On EC2
ssh -i ~/Downloads/healthline-key.pem ubuntu@YOUR_IP
mkdir healthline && tar -xzf healthline.tar.gz -C healthline
chmod +x *.sh
bash deploy-to-ec2.sh
```

### 4. Setup Domain (10 min)
```bash
# On EC2 (after DNS is configured)
bash setup-domain.sh
# Script will automatically:
# - Check DNS configuration
# - Generate SSL certificate
# - Configure nginx reverse proxy
# - Update environment variables
# - Set up auto-renewal
# - Restart services with HTTPS
```

### 5. Access
```
https://app.healthlineai.org
```

**Done! 🎉**

---

## 📁 File Guide

| File | Purpose |
|------|---------|
| `DEPLOYMENT_SUMMARY.md` | Overview & checklist |
| `AWS_DEPLOYMENT_QUICKSTART.md` | 30-min deployment guide |
| `DEPLOYMENT_GUIDE.md` | Complete 60-min guide |
| `DOMAIN_SETUP_GUIDE.md` | Domain & HTTPS setup ⭐ |
| `deploy-to-ec2.sh` | Automated setup script |
| `nginx-healthline.conf` | Nginx config for app.healthlineai.org |
| `QUICK_REFERENCE.md` | This file |

---

## 🔧 Common Commands

### View Logs
```bash
cd ~/healthline
docker compose logs -f              # All services
docker compose logs -f nginx        # Nginx only
docker compose logs -f api          # API only
docker compose logs -f ui           # UI only
```

### Control Services
```bash
docker compose --profile remote up -d      # Start all
docker compose --profile remote down       # Stop all
docker compose --profile remote restart    # Restart all
docker compose restart nginx               # Restart nginx
docker compose ps                          # Check status
```

### Check Health
```bash
curl https://app.healthlineai.org/health      # API health
docker compose ps                              # Container status
docker stats                                   # Resource usage
df -h                                          # Disk space
free -m                                        # Memory
```

### SSL Management
```bash
sudo certbot certificates               # Check expiry
sudo certbot renew --dry-run           # Test renewal
sudo certbot renew --force-renewal     # Force renew
```

### Database
```bash
docker compose exec postgres psql -U postgres                    # Access DB
docker compose exec postgres pg_dump -U postgres > backup.sql   # Backup
```

---

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| DNS not working | Wait 30 min, check `nslookup app.healthlineai.org` |
| 502 Bad Gateway | Check `docker compose ps`, restart services |
| SSL error | Check `ls -la certs/`, regenerate with certbot |
| Out of memory | Upgrade to t3.xlarge (16GB) |
| Out of disk | `docker system prune -a -f` |
| Can't connect | Check security group allows 80/443 |

---

## 📊 Architecture

```
Internet → Port 443 (HTTPS)
    ↓
EC2 Security Group
    ↓
Nginx (SSL termination)
    ├─→ UI:3010 (/)
    └─→ API:8000 (/api/*)
         ├─→ PostgreSQL:5432
         ├─→ Redis:6379
         └─→ MinIO:9000
```

---

## 💰 Costs

- **t3.large**: ~$72/month (10-50 users)
- **t3.xlarge**: ~$143/month (50-200 users)

---

## ✅ Pre-Flight Checklist

Before going live:

- [ ] EC2 instance running
- [ ] DNS pointing to EC2 IP
- [ ] SSL certificate installed
- [ ] All containers up (`docker compose ps`)
- [ ] Nginx running (`docker compose logs nginx`)
- [ ] HTTPS works (`https://app.healthlineai.org`)
- [ ] HTTP redirects to HTTPS
- [ ] API accessible (`/api/v1/health`)
- [ ] UI loads and works
- [ ] Database connected
- [ ] Redis connected
- [ ] Logs look clean
- [ ] Auto-renewal configured (`sudo certbot renew --dry-run`)
- [ ] Backups configured
- [ ] Security group locked down (only 22, 80, 443)

---

## 🔐 Security Hardening

```bash
# Change default passwords in docker-compose.yaml
nano docker-compose.yaml
# Update: POSTGRES_PASSWORD, Redis password, MinIO credentials

# Enable firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Auto security updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 📚 Documentation Links

- **Main Guide**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- **Quick Start**: [AWS_DEPLOYMENT_QUICKSTART.md](./AWS_DEPLOYMENT_QUICKSTART.md)
- **Domain Setup**: [DOMAIN_SETUP_GUIDE.md](./DOMAIN_SETUP_GUIDE.md) ⭐
- **Summary**: [DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)

---

## 🎯 Next Steps After Deployment

1. Test all features thoroughly
2. Set up monitoring (CloudWatch, Datadog)
3. Configure automated backups
4. Create staging environment
5. Set up CI/CD pipeline
6. Configure CDN (optional)
7. Add WAF (optional)

---

## 📞 Support

**Check logs first:**
```bash
docker compose logs -f
```

**Common issues:**
- Service won't start → Check logs
- Can't connect → Check security group
- SSL error → Regenerate certificate
- 502 error → Restart services

---

## 🎉 Success Criteria

✅ Visit `https://app.healthlineai.org`
✅ See green padlock (valid SSL)
✅ Healthline dashboard loads
✅ No console errors
✅ Can create workflows
✅ Can test voice agents
✅ All features work

**You're live! 🚀**

---

## 💡 Pro Tips

1. **Always use `--profile remote`** when running docker compose with nginx
2. **Monitor disk space** with `df -h` regularly
3. **Check logs daily** with `docker compose logs --tail=100`
4. **Test SSL renewal** monthly with `sudo certbot renew --dry-run`
5. **Backup database** weekly with `pg_dump`
6. **Keep system updated** with `sudo apt update && sudo apt upgrade`
7. **Use tmux/screen** for long-running commands

---

**Deploy with confidence! This guide has everything you need.** 🎯
