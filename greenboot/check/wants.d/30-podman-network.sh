#!/usr/bin/env bash
set -euo pipefail

# Podman network diagnostic check for Greenboot
# This script provides diagnostic information about podman networks

log_prefix="[greenboot-diagnostic]"

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $log_prefix $*" >&2
}

log "Starting podman network diagnostic check..."

# Check if podman is available
if ! command -v /usr/bin/podman >/dev/null 2>&1; then
    log "ERROR: podman command not found"
    exit 1
fi

# List all podman networks
log "Available podman networks:"
/usr/bin/podman network ls

# Check for Home Assistant specific network
if /usr/bin/podman network exists hass-net; then
    log "PASS: hass-net network exists"
    log "hass-net network details:"
    /usr/bin/podman network inspect hass-net
else
    log "INFO: hass-net network does not exist (this is normal for host networking)"
fi

# Check default network
if /usr/bin/podman network exists podman; then
    log "PASS: default podman network exists"
    log "Default network details:"
    /usr/bin/podman network inspect podman
else
    log "WARN: default podman network missing"
fi

# Show network usage statistics
log "Network usage summary:"
/usr/bin/podman network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Created}}\t{{.Subnets}}"

log "Podman network diagnostic completed"
