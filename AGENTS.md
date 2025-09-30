# HassOS-Bootc Repository Guidelines

## Project Structure & Module Organization
Keep the repo focused on the bootc-based Fedora image with Home Assistant. The root should expose `Containerfile`, `bindep.txt`, `README.md`, `AGENTS.md`, and `TODO.md`. Store build helpers in `build/`, systemd units in `containers-systemd/` named after their services, and Ansible assets under `ansible/` (`playbooks/`, `roles/`). Place runtime validation assets and smoke scripts under `tests/` so Day 1 and Day 2 workflows stay reproducible.

## Build, Test, and Development Commands
`podman build -t hassos-bootc:dev .` assembles the multi-stage Containerfile. `podman run --rm -it --privileged --pull=never hassos-bootc:dev bootc status` verifies bootc metadata. `bootc image build --target-arch=x86_64 --ref quay.io/yourrepo/hassos-bootc --output iso=out/hassos-bootc.iso .` generates a bootable ISO for lab checks. Run `ansible-lint ansible/playbooks/site.yml` and `ansible-playbook -i localhost, -c local --syntax-check ansible/playbooks/site.yml` before pushing. Mirror recurring routines as `make` targets if the workflow grows.

## Coding Style & Naming Conventions
Indent YAML with two spaces and group related variables (for example, `home_assistant_config`). Name Containerfile stages with lowercase hyphenated identifiers (`FROM ... AS ansible-stage`). Python helpers must pass `black scripts/`. Shell glue should start with `#!/usr/bin/env bash` and pass `shellcheck`. Prefer descriptive filenames (`bindep.fedora-42.txt`) and uppercase environment variables.

## Testing Guidelines
Run the configuration playbook locally with `ansible-playbook -i localhost, -c local ansible/playbooks/site.yml` against a disposable container or VM snapshot to prove idempotence. Capture smoke results with `podman run --rm hassos-bootc:dev /usr/bin/systemctl status home-assistant`. Keep automated checks in `tests/` and document expected outputs alongside scripts so reviewers know how to replay them.

## Day 2 Operations & Greenboot
Treat `bootc update` as the primary upgrade path and rehearse it against the latest stable image before release. Track published refs in `docs/releases.md` so operators can pin and recover with `bootc rollback`. Deploy Greenboot health checks via Ansible into `/etc/greenboot/check/required.d/` (hard fails) and `.../wants.d/` (diagnostics). Ensure scripts emit actionable logs, exit non-zero on failure, and review `journalctl -u greenboot-healthcheck` after every update campaign.

## Commit & Pull Request Guidelines
Follow Conventional Commits (for example, `feat: add home assistant service unit`) and reference issues in a footer (`Refs: #42`). Squash work so each PR tells a single story. Include command output for `podman build`, `ansible-lint`, and relevant smoke scripts, plus screenshots or logs when changing Home Assistant behavior. Flag bootc or boot media compatibility risks for reviewers.

## Security & Configuration Tips
Keep secrets out of the repository; rely on `ansible-vault` or ignored environment files. Harden systemd units with directives such as `ProtectSystem=strict` and `DynamicUser=yes`. When adding packages, justify them in `bindep.txt` and revisit `dnf install` lists to keep the image lean.
