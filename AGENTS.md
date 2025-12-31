# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

This repository provides a Dockerized MagicMirror installation with OpenTelemetry instrumentation. The Docker image bundles MagicMirror core and custom modules (MMM-BartTimes, MMM-BackgroundSlideshow) with OTLP trace export capabilities.

## Architecture

### Docker Build Process
The Dockerfile (Dockerfile:1-30) performs these key steps:
1. Clones MagicMirror core and required modules from GitHub
2. Injects OpenTelemetry instrumentation by copying `otel-init.js` and modifying MagicMirror's package.json to preload it with `--require`
3. Installs OpenTelemetry dependencies into the MagicMirror installation
4. Sets up startup script that handles environment variable substitution

### Configuration System
- Config file must be mounted at `/opt/mirror/env/config.js`
- At startup, `envsubst` processes the config file to substitute environment variables before copying to MagicMirror's config location (files/startup.sh:7)
- Optional custom startup script can be placed at `/opt/mirror/env/custom-startup.sh` and will run before the main startup (files/startup.sh:3-5)
- **Important**: The container runs as non-root user `node` (UID 1000, GID 1000). Files mounted at `/opt/mirror/env/` must be readable by UID 1000. Ensure mounted files have appropriate permissions (e.g., `chmod 644` for config.js, `chmod 755` for custom-startup.sh on the host)

### OpenTelemetry Integration
- `files/node/otel-init.js` initializes the OpenTelemetry Node SDK with OTLP HTTP trace exporter
- The MagicMirror server process automatically loads this instrumentation via Node's `--require` flag
- OTLP exporter configuration is controlled by standard OpenTelemetry environment variables

## Build Commands

### Building the Docker image
```bash
docker build -t magic-mirror .
```

### Multi-platform build (matching CI/CD)
```bash
docker buildx build --platform linux/amd64,linux/arm64 .
```

## CI/CD Pipeline

### Pull Request Validation
- CI workflow (.github/workflows/ci.yml) validates Docker builds on PRs
- Uses Docker Buildx for build testing

### Release Process
- CD workflow (.github/workflows/cd.yml) triggers on merged PRs with label `build-docker`
- Automatically tags releases based on VERSION file
- Builds and pushes multi-platform images (amd64, arm64) to Oracle Cloud Infrastructure Registry (OCIR)
- Uses reusable workflows from `tnoff/github-workflows` repository

### Version Management
- Version is tracked in the `VERSION` file at repository root
- CD pipeline reads this file to create git tags
- Current version format: semantic versioning (e.g., 0.2.1)

## Development Notes

### Modifying MagicMirror Modules
The Dockerfile clones specific MagicMirror modules:
- MMM-BartTimes: BART transit times
- MMM-BackgroundSlideshow: Background slideshow functionality

To add new modules, add git clone and npm install steps in the Dockerfile after line 10.

### OpenTelemetry Configuration
To modify instrumentation behavior, edit `files/node/otel-init.js`. The OTLP exporter endpoint and other settings can be configured via environment variables per OpenTelemetry spec (OTEL_EXPORTER_OTLP_ENDPOINT, etc.).

### Testing Configuration Changes
Since the config.js is processed by envsubst at runtime, test environment variable substitution by running the container with appropriate env vars set.
