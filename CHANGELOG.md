# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.29] - 2026-08-23

### Changed

- Build on `node:25-bookworm-slim` instead of the full `node:25-bookworm`. The full variant carries ~950 MB of build toolchain the runtime never uses; dropping it takes the image from 2.13 GB to 1.18 GB with no functional change.

## [0.2.28] - 2026-08-23

### Changed

- Requests to `/health` are no longer traced, and the duplicate `@opentelemetry/instrumentation-router` is disabled. MagicMirror's Express 5 server was being traced twice over — once by `instrumentation-express` and once by `instrumentation-router` — producing eight spans for every request, and the kubelet probes `/health` roughly 166 times for each real page view. Between them the three mirror pods were the largest single source of spans in the cluster. A `/health` probe now emits nothing at all and a real request emits four spans instead of eight, with the route name on the server span unchanged.

## [0.2.27] - 2026-08-19

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to c33d172

## [0.2.26] - 2026-08-17

### Changed

- Bumped MMM-BartTimes to 5a9fb0d — a transient 5xx from the transit feed is now retried instead of blanking the departure board until the next refresh
- Bumped MMM-BartTimes tracing — each feed fetch is one span statused on its final outcome, so a failure a retry recovered from no longer shows as an error in traces

## [0.2.25] - 2026-08-13

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to 9530be0

## [0.2.24] - 2026-08-12

### Changed

- chore(deps): update mmm-barttimes digest to f9264ac

## [0.2.23] - 2026-08-06

### Changed

- Bumped MMM-BartTimes to 5e2c9e8 — the departure board no longer goes blank when BART publishes its next static schedule ahead of the change date
- Bumped MMM-BartTimes advisory filtering — advisories can now be scoped to the stations you ride via advisory_stations

## [0.2.22] - 2026-08-05

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to f67fcdc

## [0.2.21] - 2026-07-29

### Changed

- Bumped @opentelemetry/auto-instrumentations-node to ^0.79.0

## [0.2.20] - 2026-07-29

### Changed

- chore(deps): update mmm-barttimes digest to d249dda

## [0.2.19] - 2026-07-29

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to 21573c9

## [0.2.18] - 2026-07-22

### Changed

- Bumped @opentelemetry/sdk-node to ^0.221.0

## [0.2.17] - 2026-07-08

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to e5dba3b

## [0.2.16] - 2026-07-04

### Changed

- fix(deps): update opentelemetry

## [0.2.15] - 2026-07-01

### Changed

- Bumped @opentelemetry/sdk-node to ^0.219.0

## [0.2.14] - 2026-06-29

### Changed

- Bumped @opentelemetry/auto-instrumentations-node to ^0.77.0

## [0.2.13] - 2026-06-28

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to c3e8e55

## [0.2.12] - 2026-06-15

### Changed

- chore(deps): update mmm-barttimes digest to 5c124ac

## [0.2.11] - 2026-06-14

### Changed

- chore(deps): update https://gitlab.com/tnoff-projects/github-workflows digest to 3dc971c

## [0.2.10] - 2026-06-07

### Changed

- chore(deps): update mmm-barttimes digest to b2c527d

## [0.2.9] - 2026-06-04

### Changed

- chore(deps): update mmm-barttimes digest to 13d51d4

## [0.2.8] - 2026-05-15

### Changed

- Bumped @opentelemetry/sdk-node to ^0.218.0

## [0.2.7] - 2026-05-14

### Changed

- Bumped @opentelemetry/auto-instrumentations-node to ^0.76.0

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
