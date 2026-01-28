#!/bin/bash
# Healthline Voice AI Platform - EC2 Quick Setup Script
# Run this script on your EC2 instance after SSH'ing in

set -e  # Exit on error

echo "======================================"
echo "Healthline EC2 Deployment Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get EC2 public IP
PUBLIC_IP=$(curl -s ifconfig.me)
echo -e "${GREEN}Detected EC2 Public IP: ${PUBLIC_IP}${NC}"
echo ""

# Prompt for domain (optional)
read -p "Do you have a domain name? (y/n): " has_domain
if [ "$has_domain" = "y" ]; then
    read -p "Enter your domain (e.g., healthline.com): " DOMAIN_NAME
    BACKEND_URL="https://${DOMAIN_NAME}"
    UI_URL="https://${DOMAIN_NAME}"
else
    DOMAIN_NAME=""
    BACKEND_URL="http://${PUBLIC_IP}:8000"
    UI_URL="http://${PUBLIC_IP}:3010"
fi

echo ""
echo "======================================"
echo "Step 1: Updating System"
echo "======================================"
sudo apt update && sudo apt upgrade -y

echo ""
echo "======================================"
echo "Step 2: Installing Docker"
echo "======================================"
# Install Docker
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

echo -e "${GREEN}Docker installed successfully!${NC}"
docker --version
docker compose version

echo ""
echo "======================================"
echo "Step 3: Installing Git"
echo "======================================"
sudo apt install -y git

echo ""
echo "======================================"
echo "Step 4: Checking for Code"
echo "======================================"

# Check if we're already in the healthline directory
if [ -f "docker-compose.yaml" ]; then
    echo -e "${GREEN}Found docker-compose.yaml in current directory${NC}"
    HEALTHLINE_DIR="$(pwd)"
elif [ -d ~/healthline ] && [ -f ~/healthline/docker-compose.yaml ]; then
    echo -e "${GREEN}Found healthline directory at ~/healthline${NC}"
    HEALTHLINE_DIR=~/healthline
else
    echo -e "${RED}Error: Cannot find docker-compose.yaml${NC}"
    echo ""
    echo "Please ensure you have extracted the healthline code:"
    echo "  mkdir ~/healthline"
    echo "  tar -xzf healthline.tar.gz -C ~/healthline"
    echo ""
    echo "Then run this script from the ~/healthline directory:"
    echo "  cd ~/healthline"
    echo "  bash ../deploy-to-ec2.sh"
    exit 1
fi

cd "$HEALTHLINE_DIR"
echo "Working in: $HEALTHLINE_DIR"

echo ""
echo "======================================"
echo "Step 5: Creating Environment File"
echo "======================================"

cat > .env.production << EOF
# Environment
ENVIRONMENT=production
LOG_LEVEL=INFO

# URLs
BACKEND_API_ENDPOINT=${BACKEND_URL}
UI_APP_URL=${UI_URL}

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
EOF

echo -e "${GREEN}Environment file created at ${HEALTHLINE_DIR}/.env.production${NC}"

echo ""
echo "======================================"
echo "Step 6: Starting Services"
echo "======================================"

# Start services
echo "Starting Docker containers..."
docker compose up -d --pull always

echo ""
echo "======================================"
echo "Waiting for services to start..."
echo "======================================"
sleep 30

# Check status
docker compose ps

echo ""
echo "======================================"
echo "Deployment Complete! 🎉"
echo "======================================"
echo ""
echo -e "${GREEN}Your Healthline platform is now running!${NC}"
echo ""
echo "Access URLs:"
echo -e "  ${YELLOW}UI:${NC}  ${UI_URL}"
echo -e "  ${YELLOW}API:${NC} ${BACKEND_URL}"
echo ""

if [ -z "$DOMAIN_NAME" ]; then
    echo -e "${YELLOW}NOTE:${NC} You're accessing via IP address (HTTP only)"
    echo "For production, set up a domain and HTTPS by following Step 8 in DEPLOYMENT_GUIDE.md"
    echo ""
fi

echo "Useful Commands:"
echo "  View logs:     cd ${HEALTHLINE_DIR} && docker compose logs -f"
echo "  Restart:       cd ${HEALTHLINE_DIR} && docker compose restart"
echo "  Stop:          cd ${HEALTHLINE_DIR} && docker compose down"
echo "  Update:        cd ${HEALTHLINE_DIR} && docker compose pull && docker compose up -d"
echo ""
echo -e "${GREEN}Check the logs to ensure everything started correctly:${NC}"
echo "  cd ${HEALTHLINE_DIR} && docker compose logs -f"
echo ""
echo "Press Ctrl+C to exit logs (containers will keep running)"
echo ""
echo "Current directory: ${HEALTHLINE_DIR}"
echo ""

# Follow logs
docker compose logs -f
