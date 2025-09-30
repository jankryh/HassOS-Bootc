#!/usr/bin/env bash
set -euo pipefail

# Home Assistant health check for Greenboot
# This script performs comprehensive health checks on the Home Assistant service and container

service_name=home-assistant.service
container_name=home-assistant
log_prefix="[greenboot-health]"

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $log_prefix $*" >&2
}

# Function to check service status with detailed output
check_service_status() {
    log "Checking $service_name status..."
    
    if ! /usr/bin/systemctl is-enabled --quiet "$service_name"; then
        log "ERROR: $service_name is not enabled"
        /usr/bin/systemctl status "$service_name" --no-pager -l >&2
        return 1
    fi
    
    if ! /usr/bin/systemctl is-active --quiet "$service_name"; then
        log "ERROR: $service_name is not active"
        /usr/bin/systemctl status "$service_name" --no-pager -l >&2
        return 1
    fi
    
    log "PASS: $service_name is enabled and active"
    return 0
}

# Function to check container status with detailed output
check_container_status() {
    log "Checking $container_name container status..."
    
    if ! /usr/bin/podman container exists "$container_name"; then
        log "ERROR: Container $container_name does not exist"
        /usr/bin/podman ps -a >&2
        return 1
    fi
    
    local running
    running=$(/usr/bin/podman inspect "$container_name" --format '{{ .State.Running }}')
    if [[ "$running" != "true" ]]; then
        log "ERROR: Container $container_name is not running (state: $running)"
        /usr/bin/podman inspect "$container_name" --format '{{ .State.Status }}: {{ .State.Health.Status }}' >&2
        /usr/bin/podman logs --tail 20 "$container_name" >&2
        return 1
    fi
    
    log "PASS: Container $container_name is running"
    return 0
}

# Function to check container health
check_container_health() {
    log "Checking $container_name container health..."
    
    local health_status
    health_status=$(/usr/bin/podman inspect "$container_name" --format '{{ .State.Health.Status }}' 2>/dev/null || echo "none")
    
    case "$health_status" in
        "healthy")
            log "PASS: Container $container_name is healthy"
            return 0
            ;;
        "unhealthy")
            log "ERROR: Container $container_name is unhealthy"
            /usr/bin/podman inspect "$container_name" --format '{{ range .State.Health.Log }}{{ .Output }}{{ end }}' >&2
            return 1
            ;;
        "starting")
            log "WARN: Container $container_name is still starting"
            return 0
            ;;
        "none")
            log "INFO: Container $container_name has no health check configured"
            return 0
            ;;
        *)
            log "WARN: Container $container_name has unknown health status: $health_status"
            return 0
            ;;
    esac
}

# Function to check Home Assistant web interface
check_web_interface() {
    log "Checking Home Assistant web interface..."
    
    # Wait a bit for the service to be fully ready
    sleep 2
    
    if curl -s -f -o /dev/null --connect-timeout 10 --max-time 30 http://localhost:8123/; then
        log "PASS: Home Assistant web interface is accessible"
        return 0
    else
        log "WARN: Home Assistant web interface is not accessible (may still be starting)"
        return 0  # Don't fail the health check for this
    fi
}

# Main health check execution
log "Starting Home Assistant health check..."

# Run all health checks
check_service_status || exit 1
check_container_status || exit 1
check_container_health || exit 1
check_web_interface || exit 1

log "SUCCESS: All Home Assistant health checks passed"
echo "$(date '+%Y-%m-%d %H:%M:%S') $log_prefix Home Assistant is healthy and ready"
