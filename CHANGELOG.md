# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2026-01-03

### Added
- Support for OTEL_SERVICE_NAME environment variable to configure service name in traces
- Support for custom resource attributes via OTEL_RESOURCE_ATTRIBUTES environment variable (comma-separated key=value pairs)

### Fixed
- OpenTelemetry collector connectivity by adding http:// protocol prefix to OTLP endpoint URLs

## [0.2.2] - 2025-12-30

### Security
- Container now runs as non-root user (node, UID 1000)

### Added
- AGENTS.md file for AI coding assistant guidance

## [0.2.1] - 2024-12-24

### Changed
- Upgraded base image from bullseye to bookworm (#31)
- Updated Node.js from 24 to 25 (#25)
- Updated Node.js from 23 to 24 (#23)
- Simplified Docker build process (#19)
- Updated CI/CD workflows (#27, #30)
- Removed Digital Ocean container registry push (#22)

### Added
- OpenTelemetry instrumentation with OTLP trace export (#24)
- Environment variable substitution support with `envsubst` (#26)
- Oracle Cloud Infrastructure Registry (OCIR) push support (#20)

### Fixed
- CI/CD workflow permissions issues (#28, #29)
- CI/CD workflow trigger on pull request close (#21)
- ARM build issues

### Dependencies
- Multiple oci-cli version bumps (3.51.7 → 3.53.0)

## [0.2.0] - 2025-02-22

### Added
- CI build checks on pull requests
- CODEOWNERS file

### Changed
- Upgraded Node.js from 22 to 23 (#3)

### Fixed
- Docker build context directory
- Tagging issues
- Indentation issues

### Dependencies
- Multiple oci-cli version bumps (3.50.2 → 3.51.7)

## [0.1.0] - 2024-07-25

### Added
- Initial Docker image with MagicMirror core
- MMM-BartTimes module for BART transit times
- MMM-BackgroundSlideshow module
- Docker build GitHub Actions workflow
- License file (MIT)
- Dependabot configuration
- Basic documentation

### Removed
- Scoreboards module (replaced with BART times)

[Unreleased]: https://github.com/tnoff/magic-mirror-docker/compare/v0.2.3...HEAD
[0.2.3]: https://github.com/tnoff/magic-mirror-docker/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/tnoff/magic-mirror-docker/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/tnoff/magic-mirror-docker/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/tnoff/magic-mirror-docker/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tnoff/magic-mirror-docker/releases/tag/v0.1.0
