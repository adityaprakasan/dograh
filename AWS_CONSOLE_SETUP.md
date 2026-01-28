# AWS Console Setup Guide - Before SSH

This guide covers everything you need to do in the AWS Console **before** SSH'ing into your EC2 instance.

---

## 🎯 Overview

You'll complete these tasks in the AWS Console:
1. Create EC2 instance
2. Configure security group
3. Download SSH key
4. Wait for instance to start
5. Get public IP address

**Time Required:** 10-15 minutes

---

## Step 1: Sign in to AWS Console

### 1.1 Access AWS Console
1. Go to [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Sign in with your AWS account credentials
3. Make sure you're in the correct region (top-right corner)
   - **Recommended regions:**
     - `us-east-1` (N. Virginia) - Cheapest, most services
     - `us-west-2` (Oregon) - Good alternative
     - Choose region closest to your users

---

## Step 2: Navigate to EC2

### 2.1 Open EC2 Dashboard
1. Click **Services** in top-left menu (or use search bar)
2. Search for "EC2"
3. Click **EC2** under "Compute"
4. You'll see the EC2 Dashboard

**What you'll see:**
- Resources summary (instances, volumes, key pairs, etc.)
- Launch instance button
- Recent events

---

## Step 3: Launch EC2 Instance

### 3.1 Click Launch Instance
1. Click the orange **"Launch instances"** button
2. You'll be taken to the instance configuration page

---

### 3.2 Configure Instance Name and Tags

**Name:** `healthline-production`

**Tags (optional but recommended):**
- Key: `Environment`, Value: `production`
- Key: `Project`, Value: `Healthline`
- Key: `ManagedBy`, Value: `YourName`

---

### 3.3 Choose Operating System (AMI)

**Application and OS Images (Amazon Machine Image):**

1. Select **"Quick Start"** tab (should be default)
2. Choose **"Ubuntu"**
3. Select **"Ubuntu Server 24.04 LTS (HVM), SSD Volume Type"**
   - Architecture: **64-bit (x86)**
   - **Important:** Make sure it says "Free tier eligible" or verify pricing

**Why Ubuntu 24.04 LTS?**
- Long-term support (until 2029)
- Our scripts are tested on this version
- Docker works perfectly
- Most documentation uses Ubuntu

---

### 3.4 Choose Instance Type

**Instance type:** `t3.large`

1. Click the dropdown menu showing instance types
2. Search or scroll to find **t3.large**
3. Click on it to select

**t3.large Specifications:**
- vCPUs: 2
- Memory: 8 GiB
- Network Performance: Up to 5 Gigabit
- Cost: ~$0.0832/hour (~$60/month)

**Don't see t3.large?** Try:
- Click "Compare instance types" to see all options
- Filter by: Memory = 8 GiB, vCPUs = 2

**Alternative if t3.large too expensive:**
- `t3.medium` (2 vCPU, 4GB RAM) - ~$30/month - For testing only
- Not recommended for production!

---

### 3.5 Create or Select Key Pair (CRITICAL!)

This is your SSH access key. You **cannot** download it again later!

**If you don't have a key pair:**

1. Click **"Create new key pair"**
2. **Key pair name:** `healthline-key` (or your preferred name)
3. **Key pair type:** RSA
4. **Private key file format:**
   - **Mac/Linux:** `.pem`
   - **Windows (PuTTY):** `.ppk`
   - **Windows (PowerShell/OpenSSH):** `.pem`
5. Click **"Create key pair"**
6. **File will download immediately** - Save it securely!

**Important:**
```bash
# On Mac/Linux, immediately set correct permissions:
chmod 400 ~/Downloads/healthline-key.pem

# Move to secure location
mv ~/Downloads/healthline-key.pem ~/.ssh/
```

**If you already have a key pair:**
1. Select it from the dropdown

---

### 3.6 Configure Network Settings (Security Group)

This is **critical** for allowing traffic to your application!

#### Option A: Create New Security Group (Recommended)

1. Click **"Create security group"**
2. **Security group name:** `healthline-sg`
3. **Description:** `Security group for Healthline voice AI platform`

#### Configure Inbound Rules:

You need to add **5 rules**:

**Rule 1: SSH Access**
- **Type:** SSH
- **Protocol:** TCP
- **Port range:** 22
- **Source:** My IP (your current IP - most secure)
  - Or: Anywhere (0.0.0.0/0) if your IP changes frequently
- **Description:** SSH access from my IP

**Rule 2: HTTP Traffic**
- **Type:** HTTP
- **Protocol:** TCP
- **Port range:** 80
- **Source:** Anywhere (0.0.0.0/0)
- **Description:** HTTP traffic for Let's Encrypt and redirect to HTTPS

**Rule 3: HTTPS Traffic**
- **Type:** HTTPS
- **Protocol:** TCP
- **Port range:** 443
- **Source:** Anywhere (0.0.0.0/0)
- **Description:** HTTPS traffic for application

**Rule 4: Direct UI Access (temporary, remove after deployment)**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port range:** 3010
- **Source:** My IP (or Anywhere for testing)
- **Description:** Direct UI access for testing (remove after nginx setup)

**Rule 5: Direct API Access (temporary, remove after deployment)**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port range:** 8000
- **Source:** My IP (or Anywhere for testing)
- **Description:** Direct API access for testing (remove after nginx setup)

#### How to Add Rules:
1. Click **"Add security group rule"**
2. Fill in the fields above
3. Repeat for each rule

**Security Note:**
- Ports 3010 and 8000 are temporary for initial testing
- Remove them after nginx reverse proxy is set up
- They allow direct access bypassing nginx

---

### 3.7 Configure Storage

**Storage (volumes):**

1. Root volume configuration:
   - **Size:** 30 GiB (minimum) - Recommended: 50 GiB
   - **Volume type:** gp3 (General Purpose SSD)
   - **IOPS:** 3000 (default)
   - **Throughput:** 125 MB/s (default)
   - **Delete on termination:** ✓ (checked)
   - **Encrypted:** Optional (recommended for production)

**Why 30-50 GB?**
- Docker images: ~5-10 GB
- Database storage: ~5-10 GB
- Logs and temporary files: ~5 GB
- Operating system: ~8 GB
- Room to grow: ~10-20 GB

**To change size:**
1. Look for the storage section
2. Click on the size field (default is 8 GB)
3. Change to 30 or 50

---

### 3.8 Advanced Details (Optional)

**You can skip this section for basic deployment.**

If you want to customize:

1. Click **"Advanced details"** to expand

**Useful options:**
- **IAM instance profile:** If you need AWS service access (S3, etc.)
- **Monitoring:** Enable detailed monitoring (costs extra)
- **Termination protection:** Enable to prevent accidental deletion
- **User data:** Can add bootstrap scripts (we'll do this via SSH instead)

**For Healthline deployment, defaults are fine.**

---

### 3.9 Review Summary

On the right side, you'll see a summary:

```
Number of instances: 1
Software Image (AMI): Ubuntu Server 24.04 LTS
Instance type: t3.large
Key pair: healthline-key
Network settings: healthline-sg
Storage: 30 GiB gp3
```

**Verify:**
- ✓ Instance type is correct (t3.large)
- ✓ Ubuntu 24.04 LTS selected
- ✓ Key pair selected/created
- ✓ Security group has all 5 rules
- ✓ Storage is 30+ GB

---

### 3.10 Launch Instance

1. Review everything one more time
2. Click the orange **"Launch instance"** button at the bottom right
3. You'll see a success message

**Success page shows:**
- Instance ID (e.g., `i-0123456789abcdef0`)
- Link to view instances

4. Click **"View all instances"** or **"View Instances"**

---

## Step 4: Wait for Instance to Start

### 4.1 Monitor Instance Status

On the **Instances** page, you'll see your new instance:

**Columns to watch:**

1. **Instance State:**
   - `Pending` (yellow) → Wait
   - `Running` (green) → Almost ready

2. **Status Checks:**
   - `Initializing` → Wait
   - `2/2 checks passed` (green checkmark) → Ready!

**How long?** Usually 2-3 minutes

**While waiting:**
- Don't close the browser tab
- Keep the instance selected (click the checkbox)
- Watch the status checks

### 4.2 When Ready

You'll know it's ready when you see:
- ✓ Instance state: **Running** (green)
- ✓ Status check: **2/2 checks passed** (green)
- ✓ Public IPv4 address is shown

---

## Step 5: Get Instance Information

### 5.1 Note Down Important Details

Select your instance (checkbox) and look at the **Details** tab at the bottom:

**Critical Information to Copy:**

1. **Instance ID:** `i-0123456789abcdef0`
2. **Public IPv4 address:** `54.123.45.67` ← **MOST IMPORTANT**
3. **Public IPv4 DNS:** `ec2-54-123-45-67.compute-1.amazonaws.com`
4. **Instance type:** `t3.large`
5. **Key pair name:** `healthline-key`

**Copy the Public IPv4 address** - You'll need this for:
- SSH connection
- DNS configuration
- Deployment scripts

### 5.2 Save Information

Create a note with this information:

```
Healthline Production Server
============================
Instance ID: i-0123456789abcdef0
Public IP: 54.123.45.67
Region: us-east-1
Instance Type: t3.large
Key Pair: healthline-key (file: ~/.ssh/healthline-key.pem)
SSH Command: ssh -i ~/.ssh/healthline-key.pem ubuntu@54.123.45.67
```

---

## Step 6: Configure DNS (Before or After SSH)

You can do this now or after initial deployment.

### 6.1 Go to Your Domain Registrar

Examples: GoDaddy, Namecheap, Cloudflare, Google Domains, etc.

### 6.2 Add DNS A Record

1. Find DNS Management / DNS Settings
2. Add new record:
   - **Type:** A
   - **Name:** `app` (or `@` for root domain)
   - **Value/Points to:** Your EC2 Public IP (e.g., `54.123.45.67`)
   - **TTL:** 300 seconds (5 minutes)
3. Save the record

**What this does:**
- `app.healthlineai.org` will point to your EC2 instance
- Required for SSL certificate generation
- Takes 5-30 minutes to propagate globally

### 6.3 Verify DNS (after 10-30 minutes)

**On your local computer:**
```bash
nslookup app.healthlineai.org
# Should return your EC2 IP
```

**Or use online tool:**
- Visit: https://dnschecker.org
- Enter: `app.healthlineai.org`
- Check if it shows your EC2 IP in multiple locations

---

## Step 7: Test SSH Connection (Optional but Recommended)

Before uploading code, test that SSH works:

### 7.1 Test Connection

**On Mac/Linux:**
```bash
ssh -i ~/.ssh/healthline-key.pem ubuntu@54.123.45.67
```

**On Windows PowerShell:**
```powershell
ssh -i C:\Users\YourName\.ssh\healthline-key.pem ubuntu@54.123.45.67
```

**First time connecting:**
You'll see a message like:
```
The authenticity of host '54.123.45.67 (54.123.45.67)' can't be established.
ECDSA key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no)?
```

Type: `yes` and press Enter

### 7.2 Verify You're Connected

You should see:
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux ...)

ubuntu@ip-172-31-xx-xx:~$
```

**Test basic commands:**
```bash
# Check OS version
lsb_release -a

# Check available disk space
df -h

# Check memory
free -m

# Exit
exit
```

If all this works, you're ready to deploy! ✅

---

## Step 8: Cost Estimation and Budget Alerts (Optional)

### 8.1 Set Up Billing Alerts

1. Go to AWS Console home
2. Click on your account name (top right)
3. Select **"Billing Dashboard"**
4. Click **"Budgets"** in left menu
5. Create budget:
   - **Name:** "Healthline Monthly Budget"
   - **Amount:** $100 (adjust as needed)
   - **Alert threshold:** 80%
   - **Email:** Your email

### 8.2 Enable Cost Explorer

1. In Billing Dashboard
2. Click **"Cost Explorer"**
3. Enable it (if not already enabled)
4. View your daily/monthly costs

---

## Checklist: AWS Console Tasks Complete ✅

Before SSH'ing, verify you've completed:

### Instance Setup
- [✓] EC2 instance launched
- [✓] Ubuntu 24.04 LTS selected
- [✓] Instance type: t3.large
- [✓] Storage: 30+ GB
- [✓] Instance is **Running**
- [✓] Status checks: **2/2 passed**

### Security Configuration
- [✓] Key pair created and downloaded
- [✓] Key file saved securely
- [✓] Key permissions set (`chmod 400` on Mac/Linux)
- [✓] Security group created: `healthline-sg`
- [✓] Inbound rule: SSH (port 22)
- [✓] Inbound rule: HTTP (port 80)
- [✓] Inbound rule: HTTPS (port 443)
- [✓] Inbound rule: Custom TCP 3010 (temporary)
- [✓] Inbound rule: Custom TCP 8000 (temporary)

### Information Collected
- [✓] Public IPv4 address noted
- [✓] Instance ID noted
- [✓] Region noted
- [✓] SSH command tested

### DNS Configuration
- [✓] A record created: app.healthlineai.org → EC2 IP
- [✓] DNS propagation started (takes 10-30 min)

### Optional
- [ ] Billing alerts configured
- [ ] Cost Explorer enabled
- [ ] Instance tagged appropriately

---

## What's Next?

Now you're ready to upload code and deploy! Follow these guides:

1. **Upload code:** See `AWS_DEPLOYMENT_QUICKSTART.md` - Step 3
2. **Run deployment:** See `QUICK_REFERENCE.md`
3. **Complete guide:** See `FINAL_CHECKLIST.md`

---

## Quick Reference: SSH Command

```bash
# Mac/Linux
ssh -i ~/.ssh/healthline-key.pem ubuntu@YOUR_EC2_IP

# Windows PowerShell
ssh -i C:\Users\YourName\.ssh\healthline-key.pem ubuntu@YOUR_EC2_IP
```

Replace `YOUR_EC2_IP` with your actual public IP from Step 5.

---

## Common Issues and Solutions

### Issue: "Permission denied (publickey)"

**Solution:**
```bash
# Check key permissions
ls -la ~/.ssh/healthline-key.pem

# Should be: -r-------- (400)
# Fix with:
chmod 400 ~/.ssh/healthline-key.pem
```

### Issue: "Connection timed out"

**Causes:**
1. Security group doesn't allow SSH from your IP
2. Instance not fully started
3. Wrong IP address

**Solution:**
1. Check security group has SSH rule
2. Wait 2-3 minutes after launch
3. Verify IP address is correct

### Issue: "Key file not found"

**Solution:**
```bash
# Find your key file
find ~ -name "healthline-key.pem"

# Use full path in SSH command
ssh -i /full/path/to/healthline-key.pem ubuntu@YOUR_IP
```

### Issue: Wrong username

**Common mistake:** Using `ec2-user` or `root`

**Solution:** Ubuntu instances use `ubuntu` as username:
```bash
ssh -i key.pem ubuntu@YOUR_IP  # Correct ✓
ssh -i key.pem ec2-user@YOUR_IP  # Wrong ✗
```

---

## Visual Checklist: Security Group

Your security group should look like this:

```
Inbound Rules:
┌────────┬──────────┬──────────┬─────────────┬────────────────────────┐
│ Type   │ Protocol │ Port     │ Source      │ Description            │
├────────┼──────────┼──────────┼─────────────┼────────────────────────┤
│ SSH    │ TCP      │ 22       │ My IP       │ SSH access             │
│ HTTP   │ TCP      │ 80       │ 0.0.0.0/0   │ HTTP traffic           │
│ HTTPS  │ TCP      │ 443      │ 0.0.0.0/0   │ HTTPS traffic          │
│ Custom │ TCP      │ 3010     │ 0.0.0.0/0   │ UI direct (temporary)  │
│ Custom │ TCP      │ 8000     │ 0.0.0.0/0   │ API direct (temporary) │
└────────┴──────────┴──────────┴─────────────┴────────────────────────┘

Outbound Rules:
┌────────┬──────────┬──────────┬─────────────┬────────────────────────┐
│ Type   │ Protocol │ Port     │ Destination │ Description            │
├────────┼──────────┼──────────┼─────────────┼────────────────────────┤
│ All    │ All      │ All      │ 0.0.0.0/0   │ Allow all outbound     │
└────────┴──────────┴──────────┴─────────────┴────────────────────────┘
```

---

## Cost Calculator

Use the [AWS Pricing Calculator](https://calculator.aws/) to estimate costs:

**Quick estimate for t3.large:**
- On-Demand: ~$60/month
- 1-Year Reserved: ~$37/month (save 38%)
- 3-Year Reserved: ~$25/month (save 58%)

---

## 🎉 You're Ready!

Once your instance is:
- ✅ Running
- ✅ 2/2 status checks passed
- ✅ SSH tested and working
- ✅ DNS configured

**You can proceed to deployment!**

Next step: Follow `AWS_DEPLOYMENT_QUICKSTART.md` starting at Step 3 (Upload Code).

---

**Happy deploying! 🚀**
