# Quick Reference Guide

This guide provides quick commands and examples for common installation and management tasks.

## Build Commands

### Basic Build
```bash
# Generate dependencies
./build/generate-bindep.sh > bindep.txt

# Build container image
podman build -t homeassistant-bootc:dev .

# Run tests
./tests/build-test.sh homeassistant-bootc:dev
```

### Image Generation
```bash
# Generate QCOW2 for VMs
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:dev \
  --output qcow2=out/homeassistant.qcow2 .

# Generate ISO for bare-metal
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:dev \
  --output iso=out/homeassistant.iso .

# Generate ARM64 for Raspberry Pi
bootc image build \
  --target-arch=aarch64 \
  --ref quay.io/yourrepo/homeassistant-bootc:arm64 \
  --output iso=out/homeassistant-arm64.iso .
```

## VM Commands

### QEMU/KVM
```bash
# Basic VM
qemu-system-x86_64 \
  -machine q35 \
  -cpu host \
  -m 2048 \
  -drive file=out/homeassistant.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::8123-:8123 \
  -device e1000,netdev=net0 \
  -boot order=dc

# VM with SSH access
qemu-system-x86_64 \
  -machine q35 \
  -cpu host \
  -m 2048 \
  -drive file=out/homeassistant.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::8123-:8123,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=net0 \
  -boot order=dc
```

### VirtualBox
```bash
# Create VM
VBoxManage createvm --name "HomeAssistant-bootc" --ostype Fedora_64 --register
VBoxManage modifyvm "HomeAssistant-bootc" --memory 2048 --cpus 2
VBoxManage storagectl "HomeAssistant-bootc" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "HomeAssistant-bootc" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium out/homeassistant.qcow2
VBoxManage modifyvm "HomeAssistant-bootc" --nic1 nat --nictype1 82540EM
VBoxManage startvm "HomeAssistant-bootc"
```

## USB Creation Commands

### macOS
```bash
# List disks
diskutil list

# Unmount and flash
sudo diskutil unmountDisk /dev/disk2
sudo dd if=out/homeassistant.iso of=/dev/rdisk2 bs=1m
```

### Linux
```bash
# List disks
lsblk

# Unmount and flash
sudo umount /dev/sdb1
sudo dd if=out/homeassistant.iso of=/dev/sdb bs=4M status=progress
```

### Windows
```bash
# Using PowerShell (as Administrator)
Get-Disk
Clear-Disk -Number X -RemoveData
New-Partition -DiskNumber X -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter Y -FileSystem FAT32
# Then use Rufus or similar tool
```

## System Management

### Service Control
```bash
# Check status
systemctl status home-assistant
bootc status

# Start/stop/restart
systemctl start home-assistant
systemctl stop home-assistant
systemctl restart home-assistant

# Enable/disable
systemctl enable home-assistant
systemctl disable home-assistant
```

### Container Management
```bash
# List containers
podman ps -a

# View logs
podman logs home-assistant
podman logs home-assistant --follow

# Restart container
podman restart home-assistant

# Update container
podman pull ghcr.io/home-assistant/home-assistant:stable
systemctl restart home-assistant
```

### System Updates
```bash
# Update system
bootc update --apply

# Check update status
journalctl -u bootc-fetch

# Rollback if needed
bootc rollback --list
bootc rollback --target <previous-ref>
```

## Network Configuration

### Static IP
```bash
# Configure static IP
nmcli connection modify "Wired connection 1" \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8,8.8.4.4" \
  ipv4.method manual

# Apply changes
nmcli connection up "Wired connection 1"
```

### WiFi Setup
```bash
# Scan networks
nmcli device wifi list

# Connect to WiFi
nmcli device wifi connect "SSID" password "password"

# Check connection
nmcli connection show
```

## Troubleshooting Commands

### System Diagnostics
```bash
# Check system status
systemctl status home-assistant
bootc status
podman ps -a

# View logs
journalctl -u home-assistant -f
journalctl -u greenboot-healthcheck
podman logs home-assistant

# Check resources
top
htop
free -h
df -h
```

### Network Diagnostics
```bash
# Check network
ip addr show
ip link show
nmcli device status

# Test connectivity
ping -c 3 8.8.8.8
curl -I http://localhost:8123

# Check firewall
firewall-cmd --list-all
```

### Storage Diagnostics
```bash
# Check storage
lsblk
df -h
dmesg | grep -i error

# Check filesystem
fsck /dev/sda1
```

## Health Checks

### Manual Health Checks
```bash
# Run health checks manually
/etc/greenboot/check/required.d/10-home-assistant.sh
/etc/greenboot/check/wants.d/30-podman-network.sh

# Check Greenboot status
journalctl -u greenboot-healthcheck
```

### Service Validation
```bash
# Validate Home Assistant
curl -I http://localhost:8123
systemctl is-active home-assistant
systemctl is-enabled home-assistant

# Check container health
podman inspect home-assistant --format '{{ .State.Health.Status }}'
```

## Backup and Recovery

### Configuration Backup
```bash
# Backup Home Assistant config
tar -czf homeassistant-backup-$(date +%Y%m%d).tar.gz /var/lib/home-assistant

# Backup system configuration
tar -czf system-backup-$(date +%Y%m%d).tar.gz /etc/home-assistant
```

### Recovery Commands
```bash
# Boot from recovery media
# Mount system
mkdir /mnt/sysroot
mount /dev/sda2 /mnt/sysroot

# Chroot into system
chroot /mnt/sysroot /bin/bash

# Repair services
systemctl daemon-reload
systemctl restart home-assistant
```

## Development Commands

### Testing
```bash
# Run all tests
make test

# Build and test
make build-test

# Validate Ansible
make validate-ansible

# Smoke test
./tests/smoke-test.sh homeassistant-bootc:dev
```

### Development Workflow
```bash
# Setup development environment
make dev-setup

# Development cycle
make dev

# Production build
make prod
```

## Common Issues and Solutions

### Build Issues
```bash
# Clean build
make clean
podman rmi homeassistant-bootc:dev
make build

# Check dependencies
./build/generate-bindep.sh
```

### Service Issues
```bash
# Restart everything
systemctl restart home-assistant
podman restart home-assistant

# Check logs
journalctl -u home-assistant -f
podman logs home-assistant --follow
```

### Network Issues
```bash
# Restart network
systemctl restart NetworkManager
nmcli connection up "Wired connection 1"

# Check network
ip addr show
ping -c 3 8.8.8.8
```

### Storage Issues
```bash
# Check disk space
df -h
du -sh /var/lib/home-assistant

# Clean up
podman system prune
dnf clean all
```

## Environment Variables

### Home Assistant Configuration
```bash
# Environment file location
/etc/home-assistant/home-assistant.env

# Common variables
HA_IMAGE=ghcr.io/home-assistant/home-assistant:stable
CUSTOM_COMPONENTS_DIR=/var/lib/home-assistant/custom_components
```

### System Configuration
```bash
# Bootc configuration
/etc/bootc/config.toml

# Greenboot configuration
/etc/greenboot/greenboot.conf
```

## Log Locations

### System Logs
```bash
# System logs
journalctl -u home-assistant
journalctl -u greenboot-healthcheck
journalctl -u bootc-fetch

# Container logs
podman logs home-assistant
```

### Configuration Files
```bash
# Home Assistant config
/var/lib/home-assistant/configuration.yaml

# Systemd service
/usr/lib/systemd/system/home-assistant.service

# Environment file
/etc/home-assistant/home-assistant.env
```

This quick reference provides the most commonly used commands for managing the Home Assistant bootc image. For detailed explanations and advanced scenarios, refer to the main documentation.