#!/bin/bash
# Provisions the AMI with Node.js application dependencies.
# Runs inside a temporary EC2 instance during Packer build.
set -euo pipefail

REGION="${AWS_REGION:-ap-southeast-1}"
NODE_VERSION="${NODE_VERSION:-22}"
APP_DIR="/var/www/app"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# System Update
log "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Base Packages
log "Installing base packages..."
sudo apt-get install -y \
  ca-certificates curl wget gnupg lsb-release \
  git unzip zip jq rsync \
  nginx \
  software-properties-common

# Node.js via NodeSource
log "Adding NodeSource repository for Node.js ${NODE_VERSION}.x..."
curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash -
sudo apt-get install -y nodejs

# PM2
log "Installing PM2..."
sudo npm install -g pm2
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Enable Services
log "Enabling services..."
sudo systemctl enable nginx

# AWS CLI v2
log "Installing AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

# CodeDeploy Agent
log "Installing CodeDeploy agent..."
cd /home/ubuntu
wget -q "https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install" -O install
chmod +x ./install
sudo ./install auto
rm -f ./install
sudo systemctl enable codedeploy-agent
sudo systemctl start codedeploy-agent

# App Directory
log "Creating app directory..."
sudo mkdir -p "${APP_DIR}"
sudo chown -R ubuntu:ubuntu "${APP_DIR}"

# Restart Nginx
log "Restarting nginx..."
sudo systemctl restart nginx

# Verify
log "=== Verifying installations ==="
node --version
npm --version
pm2 --version
nginx -v
aws --version
sudo systemctl status codedeploy-agent --no-pager

log "=== Setup complete ==="
