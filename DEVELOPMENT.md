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

CI is GitHub Actions. `.github/workflows/` calls reusable workflows from
`tnoff/github-workflows`, SHA-pinned and kept current by Renovate:

| Caller | Reusable workflow | Purpose |
|---|---|---|
| `ci.yml` | `trufflehog.yml` | Secret scan on PRs |
| `ci.yml` | `docker-build-check.yml` | PR-time "does the Dockerfile build" check, plus the image secret scan — one job, where GitLab needed two and a bucket to ship the tarball between them |
| `ci.yml` | `bump-version.yml` | Bump `VERSION` and write a changelog fragment on `renovate/dev-*` PRs |
| `ci.yml` | `renovate-auto-approve.yml` | Supply the code-owner approval Renovate cannot give itself |
| `release.yml` | `assemble-changelog.yml` | Fold `changelog.d/*.md` into `CHANGELOG.md` on `main` |
| `release.yml` | `tag.yml` | Read `VERSION`, push the matching git tag |
| `release.yml` | `docker-push.yml` | Build + push the image with `:<short-sha>` and `:latest` tags to OCIR |
| `release.yml` | `trigger-bump.yml` | Open an MR in `docker-apps` to bump the SHA pin after a successful push |
| `scheduled.yml` | `renovate.yml`, `branch-cleanup.yml` | Weekly dependency updates and stale-branch pruning |

`.gitlab-ci.yml` is frozen in place for history and no longer runs.

`VERSION` is the single source of truth — bump it and CI tags + pushes
the new image. Don't tag manually.

## Updating MagicMirror or modules

Three upstream refs are pinned in the Dockerfile via `ARG` + `# renovate`
comments:

| ARG | Source |
|---|---|
| `MAGICMIRROR_REF` | `MagicMirrorOrg/MagicMirror` (GitHub) |
| `MMM_BARTTIMES_REF` | `tnoff/MMM-BartTimes` (GitHub) |
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
Dockerfile patches `package.json` to add it). The OTLP *exporter* is
configured entirely via standard OTEL env vars
(`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, …) — nothing to
edit in the image for that.

The *instrumentation set* does carry two deliberate departures from the
`getNodeAutoInstrumentations()` default. Both exist because the default
made this image the single largest source of spans in the cluster:

- **`@opentelemetry/instrumentation-router` is disabled.** MagicMirror's
  server is Express 5, which routes through the standalone `router`
  package. The auto set ships an instrumentation for both, and each
  traces the same middleware chain independently — every request
  produced two parallel sets of `middleware - *` / `request handler - *`
  spans describing the identical call, one tagged `express.*` and one
  tagged `router.*`. Disabling the router one halves the per-request span
  count and loses nothing.

  Do **not** disable `instrumentation-express` as well. It is what names
  the server span after the matched route; without it the span degrades
  from `GET /` to a bare `GET`.

- **`/health` is not traced**, via `ignoreIncomingRequestHook` on
  `instrumentation-http`. The endpoint is hit by the kubelet's readiness
  (10s) and liveness (30s) probes and by nothing else, at roughly 166
  probes per real page view. Skipping the request at the HTTP layer
  suppresses the whole subtree, not just the server span:
  `instrumentation-express` only creates middleware spans inside an
  active HTTP span, so with no span to parent them it emits nothing and
  leaves no orphans behind.

To re-check either claim after a dependency bump, count the spans a
request actually produces — point `OTEL_EXPORTER_OTLP_ENDPOINT` at a
local listener and hit `/health` and `/`. As of the versions in
`files/node/package.json`, `/health` yields 0 spans and `/` yields 4.
