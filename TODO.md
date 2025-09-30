

Create a demo Containerfile that demonstrates how to use bootc with Fedora to build an image that includes Home Assistant and Ansible system roles.

The goal is:
	1.	Start from quay.io/fedora/fedora-bootc:42.
	2.	Install Home Assistant inside the container.
	3.	Show how to include Ansible system roles (for example, linux-system-roles).
	4.	Demonstrate a multi-stage build where one stage collects dependencies, and the final stage installs them.
	5.	Ensure the resulting container image can be used with bootc to produce a bootable ISO.
	6.	When the ISO is flashed to a USB stick and booted on bare metal, it should install the system automatically with Home Assistant preconfigured.

Also include a minimal example of how to integrate Ansible system roles into the build (for example using linux-system-roles.podman).

Here is a starting example you can extend and adapt:

# Stage 1: prepare ansible system roles dependencies
FROM quay.io/fedora/fedora-bootc:42 as ansible-stage
RUN dnf -y install linux-system-roles
RUN mkdir -p /deps
COPY bindep.txt /deps/
RUN /usr/share/ansible/collections/ansible_collections/fedora/linux_system_roles/roles/podman/.ostree/get_ostree_data.sh packages runtime fedora-42 raw >> /deps/bindep.txt || true

# Stage 2: main bootc image with Home Assistant
FROM quay.io/fedora/fedora-bootc:42
RUN --mount=type=bind,from=ansible-stage,source=/deps/,target=/deps \
    cat /deps/bindep.txt | xargs dnf -y install

# Install Home Assistant (minimal example)
RUN dnf -y install python3-pip && \
    pip3 install homeassistant

# Copy in example systemd units (to manage HA at boot)
COPY ./containers-systemd/* /usr/share/containers/systemd/

# Example: configure podman system role
COPY site.yml /root/site.yml

Also explain in comments how to:
	•	Run podman build -t demo-bootc-homeassistant .
	•	Use bootc to generate a bootable ISO from the built image.
	•	Flash the ISO to USB and boot on bare metal to auto-install.

⸻
