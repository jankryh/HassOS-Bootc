# syntax=docker/dockerfile:1.4-labs

## ---------------------------------------------------------------------------
## Stage 1: collect Ansible content
## ---------------------------------------------------------------------------
FROM quay.io/fedora/fedora-bootc:42 AS ansible-stage

RUN dnf -y install ansible-core linux-system-roles \
    && mkdir -p /tmp/linux-system-roles \
    && cp -a /usr/share/ansible/collections/ansible_collections/fedora/linux_system_roles \
       /tmp/linux-system-roles

## ---------------------------------------------------------------------------
## Stage 2: build bootc image with Home Assistant
## ---------------------------------------------------------------------------
FROM quay.io/fedora/fedora-bootc:42

# Install runtime dependencies and Home Assistant itself.
RUN dnf -y install python3-pip podman ansible-core greenboot systemd-udev \
    gcc python3-devel \
    && pip3 install --no-cache-dir homeassistant \
    && dnf -y remove gcc python3-devel \
    && dnf clean all

# Copy linux-system-roles data gathered in the previous stage.
COPY --from=ansible-stage /tmp/linux-system-roles \
    /usr/share/ansible/collections/ansible_collections/fedora/linux_system_roles

# Bring in repository assets used to configure the image.
COPY ansible /usr/src/ansible
COPY greenboot/check/ /etc/greenboot/check/

# Ensure health scripts are executable.
RUN chmod +x /etc/greenboot/check/required.d/* /etc/greenboot/check/wants.d/* || true

# Execute the Ansible playbook locally to lay down configuration.
RUN ANSIBLE_ROLES_PATH=/usr/src/ansible/roles \
    ANSIBLE_COLLECTIONS_PATH=/usr/share/ansible/collections \
    ansible-playbook -i localhost, -c local /usr/src/ansible/playbooks/site.yml

# Enable Home Assistant service for first boot.
RUN systemctl enable home-assistant.service || true

# Helpful build notes for contributors:
#   podman build -t hassos-bootc:dev .
#   bootc image build --target-arch=x86_64 --ref quay.io/yourrepo/hassos-bootc \
#     --output iso=out/hassos-bootc.iso .
#   Use bootc update/rollback on deployed systems for day 2 operations.
