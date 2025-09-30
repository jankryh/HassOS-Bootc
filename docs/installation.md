# Installation Guide

This guide provides detailed instructions for installing the Home Assistant bootc image on various platforms and hardware configurations.

## Table of Contents

1. [QCOW2 VM Installation](#qcow2-vm-installation)
2. [ISO Bare-Metal Installation](#iso-bare-metal-installation)
3. [Hardware-Specific Guides](#hardware-specific-guides)
4. [Advanced Configuration](#advanced-configuration)
5. [Troubleshooting](#troubleshooting)

## QCOW2 VM Installation

### Overview
QCOW2 (QEMU Copy On Write) is the recommended format for virtual machine deployments, testing, and development environments.

### Prerequisites
- **Virtualization Software**: QEMU/KVM, VirtualBox, VMware, or Hyper-V
- **System Resources**: Minimum 2GB RAM, 8GB disk space
- **Network**: Internet access for Home Assistant functionality
- **Host OS**: Linux, macOS, or Windows with virtualization support

### Step-by-Step Installation

#### 1. Build the Container Image
```bash
# Clone the repository
git clone <repository-url>
cd image_mode

# Generate dependencies
./build/generate-bindep.sh > bindep.txt

# Build the container image
podman build -t homeassistant-bootc:dev .
```

#### 2. Generate QCOW2 Image
```bash
# Create output directory
mkdir -p out

# Generate QCOW2 image
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:dev \
  --output qcow2=out/homeassistant.qcow2 .
```

#### 3. Create Virtual Machine

##### Using QEMU/KVM
```bash
# Basic QEMU command
qemu-system-x86_64 \
  -machine q35 \
  -cpu host \
  -m 2048 \
  -drive file=out/homeassistant.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::8123-:8123 \
  -device e1000,netdev=net0 \
  -boot order=dc

# Advanced QEMU with graphics
qemu-system-x86_64 \
  -machine q35 \
  -cpu host \
  -m 4096 \
  -smp 2 \
  -drive file=out/homeassistant.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::8123-:8123,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=net0 \
  -vga qxl \
  -boot order=dc
```

##### Using VirtualBox
```bash
# Create VM
VBoxManage createvm --name "HomeAssistant-bootc" --ostype Fedora_64 --register

# Configure VM settings
VBoxManage modifyvm "HomeAssistant-bootc" \
  --memory 2048 \
  --cpus 2 \
  --vram 16 \
  --acpi on \
  --ioapic on \
  --boot1 dvd \
  --boot2 disk \
  --boot3 none \
  --boot4 none

# Add storage controller
VBoxManage storagectl "HomeAssistant-bootc" \
  --name "SATA Controller" \
  --add sata \
  --controller IntelAhci

# Attach QCOW2 disk
VBoxManage storageattach "HomeAssistant-bootc" \
  --storagectl "SATA Controller" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium out/homeassistant.qcow2

# Configure network
VBoxManage modifyvm "HomeAssistant-bootc" \
  --nic1 nat \
  --nictype1 82540EM \
  --cableconnected1 on

# Start VM
VBoxManage startvm "HomeAssistant-bootc"
```

##### Using VMware
```bash
# Convert QCOW2 to VMDK
qemu-img convert -f qcow2 -O vmdk out/homeassistant.qcow2 out/homeassistant.vmdk

# Create VM in VMware with:
# - 2GB RAM
# - 2 CPU cores
# - Attach the VMDK file
# - NAT networking
```

#### 4. Access Home Assistant
```bash
# Wait for VM to boot (2-3 minutes)
# Check if Home Assistant is accessible
curl -I http://localhost:8123

# Open in browser
open http://localhost:8123  # macOS
xdg-open http://localhost:8123  # Linux
start http://localhost:8123  # Windows
```

#### 5. VM Management
```bash
# SSH access (if enabled)
ssh root@localhost -p 2222

# Check system status
systemctl status home-assistant
bootc status

# View logs
journalctl -u home-assistant -f

# Update system
bootc update --apply
```

## ISO Bare-Metal Installation

### Overview
The ISO format is designed for bare-metal hardware installation on physical devices, providing a complete operating system with Home Assistant pre-configured.

### Prerequisites
- **Hardware**: x86_64 compatible system
- **Storage**: USB drive (8GB minimum) or DVD
- **Boot**: UEFI-compatible system (BIOS mode supported)
- **Network**: Ethernet connection for Home Assistant

### Step-by-Step Installation

#### 1. Generate Bootable ISO
```bash
# Build container image
podman build -t homeassistant-bootc:dev .

# Generate bootable ISO
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:dev \
  --output iso=out/homeassistant.iso .
```

#### 2. Create Bootable Media

##### USB Drive (Recommended)
```bash
# macOS
sudo diskutil unmountDisk /dev/disk2
sudo dd if=out/homeassistant.iso of=/dev/rdisk2 bs=1m

# Linux
sudo umount /dev/sdb1
sudo dd if=out/homeassistant.iso of=/dev/sdb bs=4M status=progress

# Windows (using Rufus)
# 1. Download Rufus from https://rufus.ie/
# 2. Select USB drive
# 3. Select ISO file
# 4. Click Start
```

##### DVD (Alternative)
```bash
# Linux/macOS
growisofs -dvd-compat -Z /dev/dvd=out/homeassistant.iso

# Windows (using ImgBurn or similar)
# Burn ISO to DVD using your preferred burning software
```

#### 3. Boot and Install
1. **Insert bootable media** into target hardware
2. **Power on** the system
3. **Access BIOS/UEFI** (usually F2, F12, or Del key)
4. **Configure boot order** to boot from USB/DVD first
5. **Save and exit** BIOS/UEFI
6. **System will boot** from the media automatically
7. **Installation begins** automatically (no user interaction required)
8. **Wait for completion** (5-10 minutes depending on hardware)
9. **System reboots** automatically

#### 4. Post-Installation Setup
```bash
# Boot into the installed system
# Home Assistant starts automatically

# Check system status
systemctl status home-assistant
bootc status

# Find device IP address
ip addr show
# or
hostname -I

# Access Home Assistant web interface
# URL: http://<device-ip>:8123
```

#### 5. Initial Configuration
```bash
# Access Home Assistant web interface
# Complete the initial setup wizard
# Create admin account
# Configure location and timezone
# Add integrations as needed
```

## Hardware-Specific Guides

### Raspberry Pi 4/5
```bash
# Build ARM64 image
bootc image build \
  --target-arch=aarch64 \
  --ref quay.io/yourrepo/homeassistant-bootc:arm64 \
  --output iso=out/homeassistant-arm64.iso .

# Flash to microSD card
sudo dd if=out/homeassistant-arm64.iso of=/dev/mmcblk0 bs=4M status=progress

# Boot Raspberry Pi
# Home Assistant will be available at http://<pi-ip>:8123
```

### Intel NUC
```bash
# Standard x86_64 build
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:nuc \
  --output iso=out/homeassistant-nuc.iso .

# BIOS Configuration:
# - Enable UEFI boot
# - Disable Secure Boot
# - Set boot order to USB first
# - Enable network boot (if needed)
```

### Mini PCs (Beelink, ASUS PN, etc.)
```bash
# Standard x86_64 build works well
# Ensure UEFI boot is enabled
# Some devices may require specific BIOS settings
```

### Custom Hardware
```bash
# Check hardware compatibility
lscpu                    # CPU information
lspci                    # PCI devices
lsusb                    # USB devices
ip link show             # Network interfaces
lsblk                    # Storage devices

# Verify network connectivity
ping -c 3 8.8.8.8

# Check for hardware issues
dmesg | grep -i error
```

## Advanced Configuration

### Network Configuration

#### Static IP Setup
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

#### WiFi Configuration
```bash
# Scan for networks
nmcli device wifi list

# Connect to WiFi
nmcli device wifi connect "SSID" password "password"

# Configure WiFi with static IP
nmcli connection modify "SSID" \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.method manual
```

### Storage Configuration

#### Custom Partitioning
```bash
# For advanced users requiring custom partitioning
# Modify the Containerfile to include partitioning scripts
COPY scripts/custom-partition.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/custom-partition.sh
```

#### Additional Storage
```bash
# Add additional storage devices
lsblk
sudo mkfs.ext4 /dev/sdb1
sudo mkdir /mnt/storage
sudo mount /dev/sdb1 /mnt/storage

# Configure Home Assistant to use additional storage
# Modify systemd service to mount additional volumes
```

### Security Configuration

#### SSH Access
```bash
# Enable SSH for remote access
systemctl enable sshd
systemctl start sshd

# Configure SSH (optional)
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart sshd
```

#### Firewall Configuration
```bash
# Configure firewall
firewall-cmd --permanent --add-port=8123/tcp
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --reload
```

### Headless Installation
```bash
# For headless installations, enable SSH in Containerfile
RUN systemctl enable sshd
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Access via SSH after installation
ssh root@<device-ip>
```

## Troubleshooting

### Common Issues

#### Boot Failures
```bash
# Check UEFI/BIOS settings
# - Ensure Secure Boot is disabled
# - Verify USB drive is bootable
# - Check hardware compatibility
# - Try different USB port

# Verify boot media
file out/homeassistant.iso
```

#### Network Issues
```bash
# Check network interface
ip link show

# Verify DHCP client
systemctl status NetworkManager

# Manual network configuration
nmcli device status
nmcli connection show

# Test connectivity
ping -c 3 8.8.8.8
```

#### Home Assistant Not Starting
```bash
# Check service status
systemctl status home-assistant

# View detailed logs
journalctl -u home-assistant -f

# Check container status
podman ps -a
podman logs home-assistant

# Restart service
systemctl restart home-assistant
```

#### Storage Issues
```bash
# Check disk space
df -h

# Verify storage
lsblk

# Check for disk errors
dmesg | grep -i error

# Verify filesystem
fsck /dev/sda1
```

#### Performance Issues
```bash
# Check system resources
top
htop
free -h
iostat

# Check Home Assistant performance
podman stats home-assistant
```

### Recovery Procedures

#### Boot from Recovery Media
```bash
# Create recovery ISO with additional tools
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:recovery \
  --output iso=out/homeassistant-recovery.iso \
  --include-tools .

# Boot from recovery media
# Access system via SSH or console
# Repair or reinstall as needed
```

#### Rollback Installation
```bash
# List available rollback targets
bootc rollback --list

# Rollback to previous version
bootc rollback --target <previous-ref>

# Verify rollback success
systemctl status home-assistant
```

#### Manual Recovery
```bash
# Boot from live media
# Mount the installed system
mkdir /mnt/sysroot
mount /dev/sda2 /mnt/sysroot

# Chroot into the system
chroot /mnt/sysroot /bin/bash

# Repair as needed
systemctl status home-assistant
podman ps -a
```

### Getting Help

#### Log Collection
```bash
# Collect system logs
journalctl --since "1 hour ago" > system.log
systemctl status home-assistant > service.log
podman logs home-assistant > container.log

# Package logs for support
tar -czf logs.tar.gz system.log service.log container.log
```

#### Support Resources
- **Documentation**: Check this guide and README.md
- **Issues**: Report issues on the project repository
- **Community**: Join the Home Assistant community forums
- **Logs**: Always include relevant logs when seeking help

## Best Practices

### Security
- Change default passwords
- Enable firewall rules
- Keep system updated
- Use HTTPS for Home Assistant
- Regular backups

### Performance
- Monitor system resources
- Optimize Home Assistant configuration
- Use SSD storage for better performance
- Ensure adequate cooling

### Maintenance
- Regular system updates
- Monitor logs for issues
- Backup Home Assistant configuration
- Test updates in VM before production