# HassOS-Bootc

**Home Assistant, Container-Native** 🏠

HassOS-Bootc assembles a Fedora bootable container image that ships Home Assistant, linux-system-roles integration, and Day 2 health checks managed by Greenboot. This immutable, container-native approach provides a modern alternative to traditional Home Assistant OS deployments, optimized for bare-metal installation via bootc.

## Quick Start

### Prerequisites
- Podman 4.0+ installed
- Ansible Core 2.12+ (for validation)
- bootc CLI (for ISO generation)

### Build Process
```bash
# 1. Generate dependency hints
./build/generate-bindep.sh > bindep.txt

# 2. Build the container image
podman build -t homeassistant-bootc:dev .

# 3. Run comprehensive tests
./tests/build-test.sh homeassistant-bootc:dev

# 4. Validate Ansible configuration
./tests/validate-ansible.sh

# 5. Create a bootable ISO (optional)
bootc image build --target-arch=x86_64 --ref quay.io/yourrepo/homeassistant-bootc --output iso=out/homeassistant.iso .
```

### Quick Validation
```bash
# Smoke test the built image
./tests/smoke-test.sh homeassistant-bootc:dev

# Check bootc metadata
podman run --rm --privileged homeassistant-bootc:dev bootc status

# Verify Home Assistant service
podman run --rm homeassistant-bootc:dev /usr/bin/systemctl status home-assistant
```

## Configuration Overview

### Architecture
- **Containerfile**: Multi-stage build using Fedora bootc base image
- **Ansible**: Configuration management via `ansible/playbooks/site.yml`
- **Systemd**: Service management via `containers-systemd/home-assistant.service`
- **Greenboot**: Health monitoring via `greenboot/check/` scripts

### Key Components
- **Home Assistant**: Containerized using official image `ghcr.io/home-assistant/home-assistant:stable`
- **Podman**: Container runtime with auto-update labels
- **linux-system-roles**: Ansible collection for system configuration
- **Greenboot**: Health checks for Day 2 operations

## Practical Examples

### Custom Home Assistant Configuration
To customize Home Assistant settings, modify the environment file:

```bash
# Edit the environment template
vim ansible/roles/homeassistant.bootstrap/templates/home-assistant.env.j2

# Add custom environment variables
HA_IMAGE=ghcr.io/home-assistant/home-assistant:stable
CUSTOM_COMPONENTS_DIR=/var/lib/home-assistant/custom_components
```

### Adding Custom Components
1. Create a custom components directory:
```bash
mkdir -p /var/lib/home-assistant/custom_components
```

2. Mount it in the systemd service:
```bash
# Edit containers-systemd/home-assistant.service
--volume /var/lib/home-assistant/custom_components:/config/custom_components:Z \
```

### Network Configuration
The default configuration uses host networking. To use a custom network:

```bash
# Create a custom network
podman network create hass-net

# Modify the systemd service to use the network
--network hass-net \
```

## Day 2 Operations

### System Updates
```bash
# Update to latest image
bootc update --apply

# Verify update success
journalctl -u bootc-fetch
journalctl -u greenboot-healthcheck

# Check Home Assistant status
systemctl status home-assistant
```

### Rollback Procedures
```bash
# List available rollback targets
bootc rollback --list

# Rollback to previous version
bootc rollback --target <previous-ref>

# Verify rollback success
journalctl -u greenboot-healthcheck --since "5 minutes ago"
```

### Health Monitoring
```bash
# Check Greenboot health status
journalctl -u greenboot-healthcheck

# Run health checks manually
/etc/greenboot/check/required.d/10-home-assistant.sh
/etc/greenboot/check/wants.d/30-podman-network.sh

# Monitor Home Assistant logs
podman logs home-assistant --follow
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check build logs
podman build -t homeassistant-bootc:dev . 2>&1 | tee build.log

# Verify dependencies
./build/generate-bindep.sh

# Test Ansible syntax
ansible-playbook -i localhost, -c local --syntax-check ansible/playbooks/site.yml
```

#### Service Issues
```bash
# Check service status
systemctl status home-assistant

# View service logs
journalctl -u home-assistant -f

# Restart service
systemctl restart home-assistant

# Check container status
podman ps -a
podman logs home-assistant
```

#### Health Check Failures
```bash
# Run health checks manually
/etc/greenboot/check/required.d/10-home-assistant.sh

# Check Greenboot logs
journalctl -u greenboot-healthcheck

# Verify network connectivity
curl -I http://localhost:8123/
```

#### Network Issues
```bash
# Check podman networks
podman network ls
podman network inspect podman

# Test connectivity
podman exec home-assistant curl -I http://localhost:8123/

# Check firewall
firewall-cmd --list-all
```

### Debug Mode
Enable debug logging by modifying the environment file:

```bash
# Add debug environment variables
echo "PYTHONUNBUFFERED=1" >> /etc/home-assistant/home-assistant.env
echo "LOG_LEVEL=debug" >> /etc/home-assistant/home-assistant.env
systemctl restart home-assistant
```

### Recovery Procedures
If the system fails to boot or Home Assistant won't start:

1. **Boot from recovery media**
2. **Check system logs**: `journalctl -b`
3. **Verify container image**: `podman images`
4. **Recreate container**: `systemctl restart home-assistant`
5. **Check configuration**: `cat /var/lib/home-assistant/configuration.yaml`

## Installation Examples

### QCOW2 VM Installation

The QCOW2 format is ideal for virtual machine deployments and testing environments.

#### Prerequisites
- Virtualization software (QEMU/KVM, VirtualBox, VMware)
- At least 2GB RAM and 8GB disk space
- Network access for Home Assistant

#### Step 1: Generate QCOW2 Image
```bash
# Build the container image
podman build -t homeassistant-bootc:dev .

# Generate QCOW2 image using bootc
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:dev \
  --output qcow2=out/homeassistant.qcow2 .
```

#### Step 2: Create Virtual Machine
```bash
# Using QEMU/KVM
qemu-system-x86_64 \
  -machine q35 \
  -cpu host \
  -m 2048 \
  -drive file=out/homeassistant.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::8123-:8123 \
  -device e1000,netdev=net0 \
  -boot order=dc

# Using VirtualBox
VBoxManage createvm --name "HomeAssistant-bootc" --ostype Fedora_64 --register
VBoxManage modifyvm "HomeAssistant-bootc" --memory 2048 --cpus 2
VBoxManage storagectl "HomeAssistant-bootc" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "HomeAssistant-bootc" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium out/homeassistant.qcow2
VBoxManage modifyvm "HomeAssistant-bootc" --nic1 nat --nictype1 82540EM
VBoxManage startvm "HomeAssistant-bootc"
```

#### Step 3: Access Home Assistant
```bash
# Wait for VM to boot (2-3 minutes)
# Access Home Assistant web interface
curl http://localhost:8123

# Or open in browser
open http://localhost:8123
```

#### Step 4: VM Management
```bash
# SSH into the VM (if SSH is enabled)
ssh root@localhost -p 2222

# Check Home Assistant status
systemctl status home-assistant

# View logs
journalctl -u home-assistant -f

# Update the VM
bootc update --apply
```

### ISO Bare-Metal Installation

The ISO format is designed for bare-metal hardware installation on physical devices.

#### Prerequisites
- Physical hardware (x86_64)
- USB drive (8GB minimum)
- UEFI-compatible system
- Network connection

#### Step 1: Generate Bootable ISO
```bash
# Build the container image
podman build -t homeassistant-bootc:dev .

# Generate bootable ISO
bootc image build \
  --target-arch=x86_64 \
  --ref quay.io/yourrepo/homeassistant-bootc:dev \
  --output iso=out/homeassistant.iso .
```

#### Step 2: Create Bootable USB Drive
```bash
# On macOS
sudo diskutil unmountDisk /dev/disk2
sudo dd if=out/homeassistant.iso of=/dev/rdisk2 bs=1m

# On Linux
sudo umount /dev/sdb1
sudo dd if=out/homeassistant.iso of=/dev/sdb bs=4M status=progress

# On Windows (using Rufus or similar tool)
# Select the ISO file and USB drive, then flash
```

#### Step 3: Boot and Install
1. **Insert USB drive** into target hardware
2. **Boot from USB** (may require UEFI/BIOS configuration)
3. **Automatic installation** will begin
4. **Wait for completion** (5-10 minutes depending on hardware)
5. **System will reboot** automatically

#### Step 4: Post-Installation Setup
```bash
# Boot into the installed system
# Home Assistant will start automatically

# Check system status
systemctl status home-assistant
bootc status

# Access Home Assistant web interface
# Default URL: http://<device-ip>:8123

# Find device IP
ip addr show
```

#### Step 5: Hardware-Specific Configuration

##### Raspberry Pi 4/5
```bash
# For ARM64 devices, use ARM64 target
bootc image build \
  --target-arch=aarch64 \
  --ref quay.io/yourrepo/homeassistant-bootc:arm64 \
  --output iso=out/homeassistant-arm64.iso .
```

##### Intel NUC
```bash
# Standard x86_64 build works well
# Ensure UEFI boot is enabled in BIOS
# Network configuration may be required
```

##### Custom Hardware
```bash
# Check hardware compatibility
lscpu
lspci
lsusb

# Verify network interfaces
ip link show

# Check storage
lsblk
```

### Advanced Installation Scenarios

#### Network Configuration
```bash
# Static IP configuration (if needed)
nmcli connection modify "Wired connection 1" \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8,8.8.4.4" \
  ipv4.method manual

# Restart network
systemctl restart NetworkManager
```

#### Custom Partitioning
```bash
# For advanced users who need custom partitioning
# Modify the Containerfile to include custom partitioning scripts
COPY scripts/custom-partition.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/custom-partition.sh
```

#### Headless Installation
```bash
# For headless installations, enable SSH
# Add to Containerfile:
RUN systemctl enable sshd
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Access via SSH after installation
ssh root@<device-ip>
```

### Installation Troubleshooting

#### Common Issues

##### Boot Failures
```bash
# Check UEFI/BIOS settings
# Ensure Secure Boot is disabled
# Verify USB drive is bootable
# Check hardware compatibility
```

##### Network Issues
```bash
# Verify network interface
ip link show

# Check DHCP client
systemctl status NetworkManager

# Manual network configuration
nmcli device status
```

##### Home Assistant Not Starting
```bash
# Check service status
systemctl status home-assistant

# View detailed logs
journalctl -u home-assistant -f

# Check container status
podman ps -a
podman logs home-assistant
```

##### Storage Issues
```bash
# Check disk space
df -h

# Verify storage
lsblk

# Check for disk errors
dmesg | grep -i error
```

#### Recovery Procedures

##### Boot from Recovery Media
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

##### Rollback Installation
```bash
# List available rollback targets
bootc rollback --list

# Rollback to previous version
bootc rollback --target <previous-ref>

# Verify rollback success
systemctl status home-assistant
```

## Development

### Testing Workflow
```bash
# Run all tests
make test

# Build and test
make build-test

# Validate Ansible
make validate-ansible

# Generate dependencies
make generate-bindep
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make changes following `AGENTS.md` guidelines
4. Run tests: `./tests/build-test.sh`
5. Submit a pull request

## Documentation

- **[Installation Guide](docs/installation.md)**: Comprehensive installation instructions for QCOW2 VMs and ISO bare-metal installation
- **[Quick Reference](docs/quick-reference.md)**: Quick commands and examples for common tasks
- **[Release Notes](docs/releases.md)**: Release history and upgrade notes
- **[Contributor Guidelines](AGENTS.md)**: Coding conventions, testing expectations, and contribution guidelines

Consult `AGENTS.md` for deeper contributor guidelines, coding conventions, and testing expectations.
