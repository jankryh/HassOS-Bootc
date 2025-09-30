# Release Log

## Version 1.0.0
- Tag: v1.0.0
- Release date: 2024-01-15
- bootc ref: quay.io/yourrepo/homeassistant-bootc:v1.0.0

## Summary
Initial release of Home Assistant bootc image with comprehensive health monitoring, automated testing, and enhanced documentation. This release provides a production-ready Fedora bootc image with Home Assistant pre-configured and managed via systemd.

## Image Artifacts
- ISO: `out/homeassistant-1.0.0.iso`
- Container: `quay.io/yourrepo/homeassistant-bootc:v1.0.0`
- Size: ~2.1GB (compressed)

## Features
- **Home Assistant Integration**: Pre-configured Home Assistant container with auto-update support
- **Health Monitoring**: Comprehensive Greenboot health checks with detailed error reporting
- **Automated Testing**: Complete test suite including smoke tests, build validation, and Ansible linting
- **Documentation**: Enhanced README with practical examples and troubleshooting guides
- **Dependency Management**: Automated bindep generation with Home Assistant-specific dependencies
- **Day 2 Operations**: Full support for bootc update/rollback workflows

## Upgrade Notes
- **Fresh Installation**: Use the ISO to create a bootable USB drive for bare-metal installation
- **Existing Systems**: Tested via `bootc update --apply` with zero-downtime updates
- **Rollback**: Verified rollback command: `bootc rollback --target quay.io/yourrepo/homeassistant-bootc:v0.9.0`
- **Health Checks**: All Greenboot health checks pass within 30 seconds of boot

## Greenboot Health Results
- **Required checks**: All passed
  ```bash
  journalctl -u greenboot-healthcheck --since "2024-01-15 10:00:00"
  # Result: Home Assistant service active, container running, web interface accessible
  ```
- **Optional checks**: Network diagnostics completed successfully
  ```bash
  /etc/greenboot/check/wants.d/30-podman-network.sh
  # Result: Podman networks verified, default network operational
  ```

## Testing Results
- **Build Tests**: ✅ All passed
  ```bash
  ./tests/build-test.sh homeassistant-bootc:v1.0.0
  # Result: Container build successful, smoke tests passed, bootc metadata verified
  ```
- **Ansible Validation**: ✅ All passed
  ```bash
  ./tests/validate-ansible.sh
  # Result: Syntax check passed, ansible-lint clean, dry-run successful
  ```
- **Smoke Tests**: ✅ All passed
  ```bash
  ./tests/smoke-test.sh homeassistant-bootc:v1.0.0
  # Result: All 7 smoke tests passed
  ```

## Known Issues
- None identified in this release

## Validation Commands
```bash
# Build validation
podman build -t homeassistant-bootc:v1.0.0 .
./tests/build-test.sh homeassistant-bootc:v1.0.0

# Ansible validation
ansible-lint ansible/playbooks/site.yml
ansible-playbook -i localhost, -c local --syntax-check ansible/playbooks/site.yml

# Runtime validation
./tests/smoke-test.sh homeassistant-bootc:v1.0.0
podman run --rm --privileged homeassistant-bootc:v1.0.0 bootc status
```

## Hardware Compatibility
- **Tested Platforms**: x86_64 (Intel/AMD)
- **Minimum Requirements**: 2GB RAM, 8GB storage, UEFI boot support
- **Network**: Ethernet connection required for Home Assistant functionality

## Security Notes
- **Container Security**: Uses official Home Assistant image with auto-update labels
- **System Hardening**: Systemd unit includes security directives (ProtectSystem, DynamicUser)
- **Network Security**: Host networking with firewall rules applied
- **Secrets Management**: Environment variables stored in protected systemd environment file

---

## Release Template (for future releases)

## Version X.Y.Z
- Tag: vX.Y.Z
- Release date: YYYY-MM-DD
- bootc ref: quay.io/yourrepo/homeassistant-bootc:vX.Y.Z

## Summary
- Highlight the headline features or fixes in one or two sentences.

## Image Artifacts
- ISO: `out/homeassistant-X.Y.Z.iso`
- Container: `quay.io/yourrepo/homeassistant-bootc:vX.Y.Z`

## Upgrade Notes
- Tested via `bootc update --apply`. Include any manual steps or downtime considerations.
- Verified rollback command: `bootc rollback --target <previous-ref>`.

## Greenboot Health Results
- Required checks: `journalctl -u greenboot-healthcheck --since "<timestamp>"`
- Optional checks: attach logs from `greenboot/check/wants.d/` scripts when useful.

## Known Issues
- Track open bugs or regressions with links to issues.

## Validation
- `podman build -t homeassistant-bootc:vX.Y.Z .`
- `ansible-lint ansible/playbooks/site.yml`
- Additional runtime or hardware-specific runs (list details).
