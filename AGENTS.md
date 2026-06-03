# AGENTS.md

Guidance for AI coding agents working in this repository. For end-user
usage (mounting config, env vars, ports) see [README.md](README.md); for
build, run, and CI see [DEVELOPMENT.md](DEVELOPMENT.md).

## What this repo is

A single-Dockerfile build that bundles [MagicMirror²](https://github.com/MagicMirrorOrg/MagicMirror)
with two third-party modules and an OpenTelemetry preload, then ships
the result to OCIR.

Image surface:

- `/opt/mirror/MagicMirror/` — upstream MagicMirror, untouched except
  for the OTel preload patch
- `/opt/mirror/MagicMirror/modules/MMM-BartTimes/` —
  `tnoff-projects/MMM-BartTimes` clone
- `/opt/mirror/MagicMirror/modules/MMM-Wallpaper/` —
  `kolbyjack/MMM-Wallpaper` clone
- `/opt/mirror/env/` — the **mount point** for the user's
  `config.js` and optional `custom-startup.sh`
- `/opt/mirror/startup.sh` — runs `envsubst` over the mounted
  `config.js`, optionally execs `custom-startup.sh`, then launches the
  server

Container runs as `node` (UID 1000, GID 1000).

## Non-obvious internals

### Three Dockerfile patches to MagicMirror

The Dockerfile rewrites MagicMirror in place after the upstream tarball
is extracted:

1. **OTel preload** — `sed -i 's|node ./serveronly|node --require ./otel-init.js serveronly|'`
   on `package.json`'s `server` script. This is how the OTel SDK gets
   loaded before any MagicMirror code runs.
2. **`/health` endpoint** — `sed` inserts an Express route after the
   `/env` handler in `js/server.js`, returning `{"status":"ok"}`. The
   `HEALTHCHECK` in the Dockerfile depends on this — don't remove it.
3. **Drop the upstream `postinstall`** — a Node one-liner deletes
   `scripts.postinstall` from `package.json`. Upstream's postinstall
   shells out to `git clean`, which fails inside the image (no `.git`).

If you bump `MAGICMIRROR_REF` and either patch stops matching, the build
fails loudly — `sed` exits 0 even when no replacement happens, so check
the diff if `--require ./otel-init.js` doesn't appear in the final
image.

### `envsubst` runs at container start, not build

`config.js` is processed by `envsubst` from `gettext` every time the
container starts (`files/startup.sh`). Environment variables in the
mounted config are substituted then copied to MagicMirror's expected
location. This is why the user has to pass them via `-e` on `docker
run`, not bake them in.

### `MMM-Wallpaper`, not `MMM-BackgroundSlideshow`

Older docs referenced `MMM-BackgroundSlideshow`. The current image
ships `kolbyjack/MMM-Wallpaper` instead. If a downstream config still
references `module: "MMM-BackgroundSlideshow"`, swap it for
`MMM-Wallpaper` and adjust the per-module options to match its schema.

### Renovate-driven SHA pinning

All three upstream refs are pinned by commit SHA via `ARG`s annotated
with `# renovate: datasource=git-refs …`. Renovate opens MRs to bump
them. Don't replace the SHAs with branch names — `master` would
re-pull on every cache miss and silently break reproducibility.

## File permissions on mounted volumes

Mounts at `/opt/mirror/env/` must be readable by UID 1000. On the host:

```bash
chmod 644 /path/to/config.js
chmod 755 /path/to/custom-startup.sh   # if used
```

Otherwise the container starts but `envsubst` fails opening the file
and the symptom looks like "MagicMirror won't load my config".
