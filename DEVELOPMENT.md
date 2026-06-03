# Development

Build, test, and CI for this Docker image. End-user documentation
(mounting config, env vars, ports) lives in [README.md](README.md); for
agent-facing internals see [AGENTS.md](AGENTS.md).

## Prerequisites

- Docker with `buildx` (matches the multi-platform CI build)

## Building locally

```bash
docker build -t magic-mirror .
```

Multi-platform build (matches CI):

```bash
docker buildx build --platform linux/amd64,linux/arm64 .
```

Override a pinned upstream ref (the `# renovate:` comments in the
Dockerfile mark these for Renovate to bump):

```bash
docker build --build-arg MAGICMIRROR_REF=master -t magic-mirror:dev .
```

## Running locally

```bash
docker run --rm \
  -v "$PWD/example-config.js:/opt/mirror/env/config.js:ro" \
  -p 8080:8080 \
  magic-mirror
```

Then `curl http://localhost:8080/health` should return
`{"status":"ok"}` once the container is up.

## CI/CD

CI is GitLab CI. `.gitlab-ci.yml` pulls templates from upstream
`tnoff-projects/github-workflows`:

| Template | Purpose |
|---|---|
| `gitlab/buildkit-build-check.yml` | MR-time "does the Dockerfile build" check; produces a tarball for downstream scanning |
| `gitlab/buildkit-docker-push.yml` | Build + push the image with `:<short-sha>` and `:latest` tags to OCIR |
| `gitlab/trigger-bump.yml` | Open an MR in `docker-apps` to bump the SHA pin after a successful push |
| `gitlab/trufflehog.yml`, `gitlab/trufflehog-image.yml` | Secret scan (repo + built image) |
| `gitlab/tag.yml`, `gitlab/bump-version.yml` | Read `VERSION`, push the matching git tag, bump on default branch |
| `gitlab/renovate.yml` | Scheduled dependency updates |
| `gitlab/discord-notify.yml` | Pipeline-failure notification |

`VERSION` is the single source of truth — bump it and CI tags + pushes
the new image. Don't tag manually.

## Updating MagicMirror or modules

Three upstream refs are pinned in the Dockerfile via `ARG` + `# renovate`
comments:

| ARG | Source |
|---|---|
| `MAGICMIRROR_REF` | `MagicMirrorOrg/MagicMirror` (GitHub) |
| `MMM_BARTTIMES_REF` | `tnoff-projects/MMM-BartTimes` (GitLab) |
| `MMM_WALLPAPER_REF` | `kolbyjack/MMM-Wallpaper` (GitHub) |

Renovate watches each via the `# renovate: datasource=git-refs …`
comments above the ARG line and opens MRs to bump the SHA. Don't edit
the comments — Renovate parses them and silent breakage there means
silent staleness.

To add a new module, add another `ARG`, ADD, and `npm install` block in
the Dockerfile mirroring the existing pattern, and a matching
`# renovate:` annotation if the module lives in a git repo Renovate can
poll.

## Modifying OpenTelemetry instrumentation

`files/node/otel-init.js` is preloaded via Node's `--require` flag (the
Dockerfile patches `package.json` to add it). The OTLP exporter is
configured entirely via standard OTEL env vars
(`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, …) — no in-image
config to edit.
