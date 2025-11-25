#!/bin/bash
# Jellyfin setup script for Proxmox VM (Ubuntu/Debian) with NVIDIA GPU support
# This script configures a new Jellyfin installation using Docker,
# mounts your NAS share, and passes through the RTX 4060 GPU.
#
# Requirements:
# - A Linux VM (Ubuntu/Debian) running on Proxmox with NVIDIA GPU passthrough working.
# - The NAS share should be accessible via SMB (CIFS).
# - Docker and NVIDIA container runtime must be available.
#
# Customize these variables before running the script:
NAS_IP="192.168.1.39"
NAS_SHARE="Jellyfin"
NAS_USER="YOUR_NAS_USERNAME"
NAS_PASS="YOUR_NAS_PASSWORD"

# Exit immediately if a command exits with a non-zero status
set -e

# Create mount point for the media library
sudo mkdir -p /srv/media

# Ensure required packages are installed (CIFS utils and Docker)
sudo apt-get update
sudo apt-get install -y cifs-utils docker.io

# Create a credentials file for mounting the NAS share
sudo bash -c "echo 'username='${NAS_USER} > /root/.nas-cred"
sudo bash -c "echo 'password='${NAS_PASS} >> /root/.nas-cred"
sudo chmod 600 /root/.nas-cred

# Add the NAS share to /etc/fstab if it's not already present
FSTAB_ENTRY="//${NAS_IP}/${NAS_SHARE} /srv/media cifs credentials=/root/.nas-cred,iocharset=utf8,vers=3.0,nofail,x-systemd.automount 0 0"
if ! grep -q "${NAS_IP}/${NAS_SHARE}" /etc/fstab; then
  echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
fi

# Mount the NAS share
sudo umount /srv/media 2>/dev/null || true
sudo mount -a

# Ensure Jellyfin configuration and cache directories exist
sudo mkdir -p /srv/jellyfin/config
sudo mkdir -p /srv/jellyfin/cache
# Set ownership to the default UID used by the Jellyfin Docker image (usually 1000)
sudo chown -R 1000:1000 /srv/jellyfin

# Configure NVIDIA container runtime if available
if command -v nvidia-ctk >/dev/null 2>&1; then
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi

# Remove any existing Jellyfin container
if [ $(sudo docker ps -aq --filter name=jellyfin | wc -l) -gt 0 ]; then
  sudo docker rm -f jellyfin
fi

# Start a fresh Jellyfin container with GPU and mounted volumes
sudo docker run -d \
  --name jellyfin \
  --gpus all \
  -p 8096:8096 \
  -v /srv/jellyfin/config:/config \
  -v /srv/jellyfin/cache:/cache \
  -v /srv/media:/media \
  --restart=unless-stopped \
  jellyfin/jellyfin:latest

# Print completion message
echo "Jellyfin setup is complete. Access the UI at http://<VM_IP>:8096"
