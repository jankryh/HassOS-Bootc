#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build/generate-bindep.sh > bindep.txt
# Collect package requirements for Home Assistant bootc image by invoking
# linux-system-roles tooling inside a helper container and adding Home Assistant dependencies.

IMAGE="quay.io/fedora/fedora-bootc:42"
ROLE_PATH="/usr/share/ansible/collections/ansible_collections/fedora/linux_system_roles"
ROLE="podman"
OUTPUT_DIR="${OUTPUT_DIR:-./deps}"

mkdir -p "${OUTPUT_DIR}"

echo "[bindep] Collecting linux-system-roles dependencies..."

# Collect linux-system-roles dependencies
podman run --rm \
  --volume "${PWD}/${OUTPUT_DIR}:/deps" \
  "${IMAGE}" \
  bash -lc "\
    dnf -y install linux-system-roles >/dev/null && \
    mkdir -p /deps && \
    ${ROLE_PATH}/roles/${ROLE}/.ostree/get_ostree_data.sh packages runtime fedora-42 raw \
      >> /deps/bindep.txt || true"

echo "[bindep] Adding Home Assistant specific dependencies..."

# Add Home Assistant specific dependencies
cat >> "${OUTPUT_DIR}/bindep.txt" << 'EOF'
# Home Assistant core dependencies
python3-pip
python3-setuptools
python3-wheel

# System dependencies for Home Assistant
python3-dev
gcc
gcc-c++
make
openssl-devel
libffi-devel
python3-devel

# Additional runtime dependencies
curl
wget
git
tar
gzip

# Network and security
firewalld
openssh-clients

# Container runtime dependencies
podman
buildah
skopeo

# System monitoring and health checks
greenboot
systemd-udev

# Ansible and automation
ansible-core
EOF

echo "[bindep] Deduplicating package list..."

# Sort and deduplicate the package list
sort "${OUTPUT_DIR}/bindep.txt" | uniq > "${OUTPUT_DIR}/bindep-sorted.txt"
mv "${OUTPUT_DIR}/bindep-sorted.txt" "${OUTPUT_DIR}/bindep.txt"

echo "[bindep] Generated bindep.txt with $(wc -l < "${OUTPUT_DIR}/bindep.txt") packages"
cat "${OUTPUT_DIR}/bindep.txt"
