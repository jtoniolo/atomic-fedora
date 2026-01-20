# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

atomic-fedora is a custom OStree (immutable) Fedora container image builder using the **BlueBuild** framework. It creates multiple specialized atomic Fedora variants published to GitHub Container Registry (ghcr.io).

## Build Commands

### Local Building

```bash
# Interactive build (prompts for recipe selection)
./build.sh

# Non-interactive build (pass recipe path as argument)
./build.sh recipes/workstation.yml
./build.sh recipes/server.yml
./build.sh recipes/dad-surface.yml
```

### ISO Generation

```bash
# From local recipe
sudo bluebuild generate-iso --iso-name atomic-workstation.iso recipe recipes/workstation.yml

# From published image
sudo bluebuild generate-iso --iso-name atomic-workstation.iso image ghcr.io/jtoniolo/atomic-workstation
```

### CI/CD

Builds are triggered via GitHub Actions on push to main, daily schedule (06:00 UTC), or manual dispatch. Matrix builds process all recipes in parallel.

```bash
gh workflow run build.yml
gh workflow run build.yml -f push_image=true  # Push to registry
```

## Architecture

### Recipe Files (`/recipes/*.yml`)

YAML recipes define images using the BlueBuild schema (`https://schema.blue-build.org/recipe-v1.json`):

- **workstation.yml** - Developer workstation for ThinkPad T14 AMD (aurora-dx base)
- **server.yml** - Homelab/media server (ucore-hci base)
- **dad-surface.yml** - Microsoft Surface setup (aurora-surface base)

Note: `recipe.yml` is the default template from the original BlueBuild repo, not an active recipe.

### Build Module Execution Order

1. **files** - Copies custom files from `files/` directory
2. **dnf** - Adds repositories and installs/removes packages
3. **containerfile** - Runs inline Containerfile RUN commands
4. **script** - Executes shell scripts (e.g., `build-evdi.sh`)
5. **systemd** - Enables/disables systemd services
6. **default-flatpaks** - Sets up Flatpak repos and installs apps
7. **signing** - Sets up image signing policy and keys

### Key Directories

- `recipes/` - Image recipe definitions (YAML)
- `files/dnf/` - Custom DNF repository configurations
- `files/scripts/` - Build-time shell scripts
- `files/system/` - Root filesystem overrides (etc/, usr/)
- `modules/` - Custom BlueBuild modules (currently empty)

### DisplayLink/EVDI Support

`files/scripts/build-evdi.sh` compiles the EVDI kernel module for DisplayLink USB docking stations. It detects the kernel version, builds via akmods, and installs the resulting module. Used by workstation.yml and dad-surface.yml.

## Published Images

- `ghcr.io/jtoniolo/atomic-workstation`
- `ghcr.io/jtoniolo/atomic-server`
- `ghcr.io/jtoniolo/atomic-dad-surface`

Images are signed with cosign. Verify with: `cosign verify --key cosign.pub ghcr.io/jtoniolo/atomic-workstation`

## Base Images (Universal Blue)

- `ghcr.io/ublue-os/aurora-dx` - KDE Plasma developer-focused (workstation)
- `ghcr.io/ublue-os/ucore-hci` - Headless server (server)
- `ghcr.io/ublue-os/aurora-surface` - Microsoft Surface optimized (dad-surface)

## BlueBuild Documentation

Reference: https://blue-build.org/
