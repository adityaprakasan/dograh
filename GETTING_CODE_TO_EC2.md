# Getting Your Code to EC2 Instance

There are two ways to get your Healthline code onto the EC2 instance. Choose the method that works best for you.

---

## Option 1: Clone from GitHub (Recommended if repo is on GitHub)

**Use this if:** Your code is already pushed to a GitHub repository.

### Step 1: SSH into EC2

```bash
ssh -i ~/.ssh/healthline-key.pem ubuntu@YOUR_EC2_IP
```

### Step 2: Install Git (if not already installed)

```bash
sudo apt update
sudo apt install git -y
```

### Step 3: Clone the Repository

**If repository is public:**
```bash
cd ~
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git healthline
cd healthline
```

**If repository is private:**
```bash
# Option A: Use SSH key (recommended)
# First, add your GitHub SSH key to the instance
# Then clone:
cd ~
git clone git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git healthline
cd healthline

# Option B: Use personal access token
cd ~
git clone https://YOUR_TOKEN@github.com/YOUR_USERNAME/YOUR_REPO_NAME.git healthline
cd healthline
```

**If you need to clone a specific branch:**
```bash
cd ~
git clone -b YOUR_BRANCH_NAME https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git healthline
cd healthline
```

### Step 4: Verify Code is There

```bash
ls -la
# Should see: docker-compose.yaml, api/, ui/, etc.
```

### Step 5: Continue with Deployment

```bash
# Make scripts executable (if they're in the repo)
chmod +x deploy-to-ec2.sh setup-domain.sh

# Run deployment
bash deploy-to-ec2.sh
```

---

## Option 2: Upload from Local Machine (Current Method)

**Use this if:** Your code is only on your local machine, or you want to upload a specific version.

### Step 1: Package Code on Your Local Machine

**On your Mac:**
```bash
cd /Users/aditya/Desktop/dograh

# Create tarball excluding unnecessary files
tar -czf healthline.tar.gz \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.env' \
  --exclude='*.log' \
  .
```

### Step 2: Upload to EC2

**On your Mac:**
```bash
# Upload code tarball
scp -i ~/.ssh/healthline-key.pem \
    healthline.tar.gz \
    ubuntu@YOUR_EC2_IP:~/

# Upload deployment scripts
scp -i ~/.ssh/healthline-key.pem \
    deploy-to-ec2.sh \
    setup-domain.sh \
    ubuntu@YOUR_EC2_IP:~/
```

### Step 3: Extract on EC2

**SSH into EC2:**
```bash
ssh -i ~/.ssh/healthline-key.pem ubuntu@YOUR_EC2_IP
```

**Extract the code:**
```bash
# Create directory
mkdir -p ~/healthline

# Extract tarball
tar -xzf healthline.tar.gz -C ~/healthline

# Verify files
cd ~/healthline
ls -la
# Should see: docker-compose.yaml, api/, ui/, etc.

# Make scripts executable
chmod +x ~/deploy-to-ec2.sh ~/setup-domain.sh
```

### Step 4: Continue with Deployment

```bash
# Run from healthline directory or use full paths
cd ~/healthline
bash ~/deploy-to-ec2.sh
```

---

## Comparison: Which Method to Use?

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Git Clone** | ✅ Fast<br>✅ Always latest code<br>✅ Easy updates<br>✅ Version control | ❌ Requires GitHub access<br>❌ Need to handle private repos | Code already on GitHub |
| **SCP Upload** | ✅ Works offline<br>✅ No GitHub needed<br>✅ Upload specific version | ❌ Slower for large repos<br>❌ Manual process<br>❌ Need to re-upload for updates | Local-only code or specific builds |

---

## Quick Reference: First Command

### If Using GitHub Clone:

```bash
# SSH into EC2 first
ssh -i ~/.ssh/healthline-key.pem ubuntu@YOUR_EC2_IP

# Then clone (this is the "first command" to get code)
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git healthline
```

### If Using SCP Upload:

```bash
# On your LOCAL machine (not EC2)
# First package, then upload:
cd /Users/aditya/Desktop/dograh
tar -czf healthline.tar.gz --exclude='.git' --exclude='node_modules' .
scp -i ~/.ssh/healthline-key.pem healthline.tar.gz ubuntu@YOUR_EC2_IP:~/

# Then SSH and extract:
ssh -i ~/.ssh/healthline-key.pem ubuntu@YOUR_EC2_IP
tar -xzf healthline.tar.gz -C ~/healthline
```

---

## Troubleshooting

### Git Clone Issues

**Problem: "Permission denied (publickey)"**
```bash
# Solution: Use HTTPS with token instead
git clone https://YOUR_TOKEN@github.com/USERNAME/REPO.git healthline
```

**Problem: "Repository not found"**
```bash
# Check: Is repo private? Use SSH or token
# Check: Is repo name correct?
# Check: Do you have access?
```

**Problem: "Command not found: git"**
```bash
# Install git first
sudo apt update
sudo apt install git -y
```

### SCP Upload Issues

**Problem: "Permission denied"**
```bash
# Fix key permissions
chmod 400 ~/.ssh/healthline-key.pem

# Try again
scp -i ~/.ssh/healthline-key.pem healthline.tar.gz ubuntu@YOUR_IP:~/
```

**Problem: "Connection timed out"**
```bash
# Check: Is security group allowing SSH from your IP?
# Check: Is instance running?
# Check: Is IP address correct?
```

**Problem: "No space left on device"**
```bash
# Check disk space on EC2
df -h

# Clean up if needed
docker system prune -a -f
```

---

## Recommended Workflow

**For most users, I recommend:**

1. **First time deployment:** Use SCP upload (Option 2)
   - Ensures you upload exactly what you have locally
   - No need to push to GitHub first

2. **Updates and redeployments:** Use Git clone (Option 1)
   - Faster for updates
   - Always get latest code
   - Better for CI/CD

---

## Next Steps After Getting Code

Once code is on EC2 (either method):

```bash
# Navigate to code directory
cd ~/healthline

# Verify files are there
ls -la

# Run deployment script
bash deploy-to-ec2.sh
```

---

## Summary: The "First Command"

**If cloning from GitHub:**
```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git healthline
```

**If uploading from local:**
```bash
# On local machine:
scp -i ~/.ssh/healthline-key.pem healthline.tar.gz ubuntu@YOUR_EC2_IP:~/

# Then on EC2:
tar -xzf healthline.tar.gz -C ~/healthline
```

Choose the method that fits your workflow! 🚀
