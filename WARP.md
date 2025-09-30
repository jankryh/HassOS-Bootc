# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Build and Test Workflow
```bash
# Build the bootc container image
podman build -t homeassistant-bootc:dev .

# Run comprehensive tests (recommended before committing)
make test

# Run individual test components
make build-test           # Build and validate the image
make smoke-test          # Quick functionality validation  
make validate-ansible    # Ansible configuration validation

# Generate dependency hints
make generate-bindep     # Creates bindep.txt from current system

# Development cycle (setup + build + test)
make dev

# Production-ready build
make prod
```

### Image Generation
```bash
# Generate VM image for testing
make qcow2

# Generate bootable ISO for bare-metal installation
make iso

# Generate ARM64 ISO for Raspberry Pi
make iso-arm64

# Generate all image formats
make images
```

### Testing Individual Components
```bash
# Test built image functionality
./tests/smoke-test.sh homeassistant-bootc:dev

# Validate Ansible without building
./tests/validate-ansible.sh

# Comprehensive build validation
./tests/build-test.sh homeassistant-bootc:test
```

## Architecture Overview

### Multi-Stage Container Build
The project uses a two-stage Containerfile approach:
1. **ansible-stage**: Collects linux-system-roles from Fedora packages
2. **Main stage**: Builds the final bootc image with Home Assistant and dependencies

### Key Components Integration
- **Fedora bootc**: Immutable OS foundation with atomic updates via `bootc update/rollback`
- **Home Assistant**: Containerized using official ghcr.io images, managed by systemd
- **Ansible**: Configuration management using custom `homeassistant.bootstrap` role
- **Greenboot**: Health monitoring with required checks (`10-home-assistant.sh`) and diagnostics (`30-podman-network.sh`)
- **Podman**: Container runtime with auto-update labels and SELinux contexts

### Configuration Flow
```
Containerfile → Ansible (ansible/playbooks/site.yml) → homeassistant.bootstrap role → 
  - systemd unit (templates/home-assistant.service)
  - environment file (templates/home-assistant.env.j2) 
  - directories (/var/lib/home-assistant, /etc/home-assistant)
  - default configuration.yaml
```

### Runtime Architecture
- Home Assistant runs in a podman container with host networking
- Configuration persisted in `/var/lib/home-assistant:/config`
- Environment variables from `/etc/home-assistant/home-assistant.env`
- Auto-updates via podman's `io.containers.autoupdate=image` label
- Health monitoring via Greenboot on system updates

## Development Patterns

### Making Configuration Changes
1. Modify Ansible role in `ansible/roles/homeassistant.bootstrap/`
2. Update templates in `templates/` directory for systemd units or environment files
3. Test locally: `make validate-ansible && make build-test`
4. Verify in container: `podman run --rm imageref /usr/bin/systemctl status home-assistant`

### Adding New Services or Components
1. Create new Ansible tasks in `homeassistant.bootstrap/tasks/main.yml`
2. Add corresponding systemd units to `containers-systemd/` for reference
3. Add health checks to `greenboot/check/required.d/` (critical) or `wants.d/` (diagnostic)
4. Update test scripts in `tests/` to validate new functionality

### Greenboot Health Checks
- **Required checks** (`greenboot/check/required.d/`): System fails to boot if these fail
- **Diagnostic checks** (`greenboot/check/wants.d/`): Provide monitoring info but don't block boot
- All scripts must be executable and follow the logging pattern with timestamps

### Testing New Features
1. Build test image: `podman build -t homeassistant-bootc:test .`
2. Run smoke tests: `./tests/smoke-test.sh homeassistant-bootc:test`
3. Test in VM: `make qcow2` and boot in virtualization software
4. Validate bootc operations: `bootc status`, `bootc update --check`

## Coding Conventions

### File Organization
- `ansible/roles/homeassistant.bootstrap/`: Main Ansible role for configuration
- `containers-systemd/`: Reference systemd units (deployed via Ansible templates)
- `greenboot/check/`: Health monitoring scripts
- `tests/`: Validation and testing scripts
- `build/`: Build helper utilities

### Ansible Patterns
- Use `ansible.builtin` modules explicitly
- Template files end in `.j2` and use Jinja2 variables with defaults
- Directory creation with explicit owner/group/mode settings
- Use `ignore_errors: true` for systemd operations during build

### Shell Script Standards
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Use descriptive logging with timestamps: `echo "$(date '+%Y-%m-%d %H:%M:%S') [script] message"`
- Implement cleanup functions with `trap cleanup EXIT`
- Exit codes: 0 for success, 1 for failures

### Container Build Practices
- Multi-stage builds to minimize final image size
- Clean dnf cache with `dnf clean all`
- Remove build dependencies after installation
- Use explicit package versions when stability is critical
- Preserve ansible collections and systemd configurations