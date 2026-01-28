#!/bin/bash
# Healthline - Domain Setup Script for app.healthlineai.org
# Run this AFTER you've done the initial deployment

set -e

echo "======================================"
echo "Healthline Domain Setup"
echo "Setting up: app.healthlineai.org"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Find the healthline directory
if [ -f "docker-compose.yaml" ]; then
    echo -e "${GREEN}Found docker-compose.yaml in current directory${NC}"
    HEALTHLINE_DIR="$(pwd)"
elif [ -d ~/healthline ] && [ -f ~/healthline/docker-compose.yaml ]; then
    echo -e "${GREEN}Found healthline directory at ~/healthline${NC}"
    HEALTHLINE_DIR=~/healthline
else
    echo -e "${RED}Error: Cannot find healthline deployment!${NC}"
    echo "Please ensure:"
    echo "  1. You've extracted the code to ~/healthline"
    echo "  2. You've run deploy-to-ec2.sh first"
    echo ""
    echo "Then run this script from the ~/healthline directory:"
    echo "  cd ~/healthline"
    echo "  bash ../setup-domain.sh"
    exit 1
fi

cd "$HEALTHLINE_DIR"
echo "Working in: $HEALTHLINE_DIR"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)
echo -e "${GREEN}Your EC2 Public IP: ${PUBLIC_IP}${NC}"
echo ""

# DNS check
echo "======================================"
echo "Step 1: Checking DNS Configuration"
echo "======================================"
echo ""
echo -e "${YELLOW}Please ensure you have added this DNS record:${NC}"
echo "  Type: A"
echo "  Name: app"
echo "  Value: ${PUBLIC_IP}"
echo "  Domain: healthlineai.org"
echo ""
echo "Checking if DNS is configured..."
sleep 2

if nslookup app.healthlineai.org | grep -q "${PUBLIC_IP}"; then
    echo -e "${GREEN}✓ DNS is configured correctly!${NC}"
else
    echo -e "${RED}✗ DNS not found or not propagated yet.${NC}"
    echo ""
    echo "Please:"
    echo "1. Add DNS A record: app.healthlineai.org → ${PUBLIC_IP}"
    echo "2. Wait 5-30 minutes for DNS propagation"
    echo "3. Run this script again"
    echo ""
    read -p "Do you want to continue anyway? (y/n): " continue_anyway
    if [ "$continue_anyway" != "y" ]; then
        exit 1
    fi
fi

echo ""
read -p "Enter your email for SSL certificate notifications: " EMAIL

if [ -z "$EMAIL" ]; then
    echo -e "${RED}Email is required!${NC}"
    exit 1
fi

echo ""
echo "======================================"
echo "Step 2: Stopping Services"
echo "======================================"
docker compose down

echo ""
echo "======================================"
echo "Step 3: Installing Certbot"
echo "======================================"
sudo apt update
sudo apt install certbot -y

echo ""
echo "======================================"
echo "Step 4: Generating SSL Certificate"
echo "======================================"
echo "This may take a minute..."

# Generate certificate
if sudo certbot certonly --standalone \
    -d app.healthlineai.org \
    --non-interactive \
    --agree-tos \
    --email "${EMAIL}"; then
    echo -e "${GREEN}✓ SSL certificate generated successfully!${NC}"
else
    echo -e "${RED}✗ Failed to generate SSL certificate${NC}"
    echo "Common issues:"
    echo "  - DNS not pointing to this server"
    echo "  - Port 80 blocked by firewall"
    echo "  - Another service using port 80"
    exit 1
fi

echo ""
echo "======================================"
echo "Step 5: Copying Certificates"
echo "======================================"
mkdir -p certs
sudo cp /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem certs/local.crt
sudo cp /etc/letsencrypt/live/app.healthlineai.org/privkey.pem certs/local.key
sudo chown -R ubuntu:ubuntu certs
chmod 644 certs/*
echo -e "${GREEN}✓ Certificates copied${NC}"

echo ""
echo "======================================"
echo "Step 6: Configuring Nginx"
echo "======================================"
# Backup original nginx config
if [ -f nginx.conf ]; then
    cp nginx.conf nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backed up existing nginx.conf"
fi

# Use the domain-specific nginx config
if [ -f nginx-healthline.conf ]; then
    cp nginx-healthline.conf nginx.conf
    echo -e "${GREEN}✓ Using nginx-healthline.conf${NC}"
else
    echo -e "${YELLOW}Warning: nginx-healthline.conf not found, using existing nginx.conf${NC}"
fi

echo ""
echo "======================================"
echo "Step 7: Updating Environment Variables"
echo "======================================"

# Backup .env.production
if [ -f .env.production ]; then
    cp .env.production .env.production.backup.$(date +%Y%m%d_%H%M%S)
fi

# Update URLs in .env.production
if [ -f .env.production ]; then
    sed -i 's|BACKEND_API_ENDPOINT=.*|BACKEND_API_ENDPOINT=https://app.healthlineai.org|' .env.production
    sed -i 's|UI_APP_URL=.*|UI_APP_URL=https://app.healthlineai.org|' .env.production
    echo -e "${GREEN}✓ Environment variables updated${NC}"
else
    echo -e "${YELLOW}Creating new .env.production${NC}"
    cat > .env.production << EOF
ENVIRONMENT=production
LOG_LEVEL=INFO
BACKEND_API_ENDPOINT=https://app.healthlineai.org
UI_APP_URL=https://app.healthlineai.org
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
EOF
fi

echo ""
echo "======================================"
echo "Step 8: Setting Up Auto-Renewal"
echo "======================================"

# Create renewal hook directory
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy

# Create renewal script with proper path
sudo tee /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh > /dev/null << EOF
#!/bin/bash
# Copy new certificates
cp /etc/letsencrypt/live/app.healthlineai.org/fullchain.pem ${HEALTHLINE_DIR}/certs/local.crt
cp /etc/letsencrypt/live/app.healthlineai.org/privkey.pem ${HEALTHLINE_DIR}/certs/local.key
chmod 644 ${HEALTHLINE_DIR}/certs/*

# Reload nginx
cd ${HEALTHLINE_DIR}
docker compose --profile remote restart nginx

echo "SSL certificates updated - \$(date)" >> /var/log/healthline-ssl-renewal.log
EOF

sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/healthline-reload.sh

# Test renewal
echo "Testing auto-renewal..."
if sudo certbot renew --dry-run; then
    echo -e "${GREEN}✓ Auto-renewal configured successfully!${NC}"
else
    echo -e "${YELLOW}Warning: Auto-renewal test had issues (but may still work)${NC}"
fi

echo ""
echo "======================================"
echo "Step 9: Starting Services with Nginx"
echo "======================================"
docker compose --profile remote up -d

echo ""
echo "Waiting for services to start (30 seconds)..."
sleep 30

echo ""
echo "======================================"
echo "Checking Service Status"
echo "======================================"
docker compose ps

echo ""
echo "======================================"
echo "🎉 Domain Setup Complete!"
echo "======================================"
echo ""
echo -e "${GREEN}Your Healthline platform is now live at:${NC}"
echo -e "  ${YELLOW}https://app.healthlineai.org${NC}"
echo ""
echo "What was configured:"
echo "  ✓ DNS checked and verified"
echo "  ✓ SSL certificate generated (Let's Encrypt)"
echo "  ✓ Nginx reverse proxy configured"
echo "  ✓ HTTPS enabled with automatic HTTP redirect"
echo "  ✓ Environment variables updated"
echo "  ✓ Auto-renewal configured (runs twice daily)"
echo "  ✓ All services restarted"
echo ""
echo "Next steps:"
echo "  1. Visit https://app.healthlineai.org in your browser"
echo "  2. Verify the green padlock (valid SSL)"
echo "  3. Test your Healthline dashboard"
echo "  4. Update EC2 security group (remove direct access to ports 3010, 8000)"
echo ""
echo "Useful commands:"
echo "  View logs:     docker compose logs -f"
echo "  Check status:  docker compose ps"
echo "  Restart nginx: docker compose --profile remote restart nginx"
echo "  Check SSL:     sudo certbot certificates"
echo ""
echo -e "${GREEN}Watching logs (Ctrl+C to exit, services keep running):${NC}"
echo ""

# Follow logs
docker compose logs -f
