# -slim, not the full node image. The full variant carries ~950 MB of build
# toolchain (a 588 MB apt layer among others) that nothing here needs: the
# runtime is `node serveronly`, and the only build-time package required is
# gettext, installed below. Measured on amd64: 2.13 GB -> 1.18 GB, a 45% cut,
# with the image verified at parity -- same node v25.9.0, envsubst present,
# identical 658 node_modules packages, both source patches applied.
FROM node:25-bookworm-slim

# Setup basics
# Update to latest for security fixes
RUN apt-get update && \
    apt-get install -y gettext && \
    apt-get upgrade -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# renovate: datasource=git-refs depName=MagicMirror packageName=https://github.com/MagicMirrorOrg/MagicMirror currentValue=master
ARG MAGICMIRROR_REF=fb41d24ef522e91e802e2a623ff6afbddeb3c9d8
# MMM-BartTimes flipped to GitHub-canonical; the GitLab copy is frozen at this
# very SHA, so a git-refs datasource pointed there would report "up to date"
# forever and this pin would silently stop moving. Same archive byte-for-byte
# (74538 bytes, 25 entries) -- verified 2026-08-27.
# renovate: datasource=git-refs depName=MMM-BartTimes packageName=https://github.com/tnoff/MMM-BartTimes currentValue=main
ARG MMM_BARTTIMES_REF=5a9fb0d6ad2762eef45da1aee0c6a578536da07e
# renovate: datasource=git-refs depName=MMM-Wallpaper packageName=https://github.com/kolbyjack/MMM-Wallpaper currentValue=master
ARG MMM_WALLPAPER_REF=86a0df464eab14d95cde697fa472b46e27997cfb

# Setup mirror
RUN mkdir -p /opt/mirror/MagicMirror
ADD https://github.com/MagicMirrorOrg/MagicMirror/archive/${MAGICMIRROR_REF}.tar.gz /tmp/magicmirror.tgz
RUN tar -xzf /tmp/magicmirror.tgz -C /opt/mirror/MagicMirror --strip-components=1 \
 && rm /tmp/magicmirror.tgz
RUN chown -R node:node /opt/mirror
COPY files/node/otel-init.js /opt/mirror/MagicMirror/
COPY files/startup.sh /opt/mirror
RUN chmod +x /opt/mirror/startup.sh

USER node

RUN mkdir -p /opt/mirror/MagicMirror/modules/MMM-BartTimes \
             /opt/mirror/MagicMirror/modules/MMM-Wallpaper
ADD --chown=node:node https://github.com/tnoff/MMM-BartTimes/archive/${MMM_BARTTIMES_REF}.tar.gz /tmp/bart.tgz
RUN tar -xzf /tmp/bart.tgz -C /opt/mirror/MagicMirror/modules/MMM-BartTimes --strip-components=1 \
 && rm /tmp/bart.tgz
ADD --chown=node:node https://github.com/kolbyjack/MMM-Wallpaper/archive/${MMM_WALLPAPER_REF}.tar.gz /tmp/wallpaper.tgz
RUN tar -xzf /tmp/wallpaper.tgz -C /opt/mirror/MagicMirror/modules/MMM-Wallpaper --strip-components=1 \
 && rm /tmp/wallpaper.tgz

# Add in instrumentation files
RUN sed -i.bak 's|"server": "node ./serveronly"|"server": "node --require ./otel-init.js serveronly"|' /opt/mirror/MagicMirror/package.json
RUN sed -i '/app\.get("\/env".*getEnvVars/a\    app.get("/health", (req, res) => res.json({ status: "ok" }));' /opt/mirror/MagicMirror/js/server.js
# Strip MagicMirror's postinstall (it shells out to `git clean`, which has nothing to do without a .git dir)
RUN node -e 'const fs=require("fs"),p="/opt/mirror/MagicMirror/package.json",j=JSON.parse(fs.readFileSync(p));delete j.scripts.postinstall;fs.writeFileSync(p,JSON.stringify(j,null,2));'
# Run install on custom modules
WORKDIR /opt/mirror/MagicMirror/modules/MMM-BartTimes
# --omit=dev: the module's devDependencies are its test-only OpenTelemetry SDK
# (~18MB), which nothing at runtime imports — the SDK the module's spans
# actually report through is the one installed below from files/node.
RUN npm install --omit=dev
WORKDIR /opt/mirror/MagicMirror/modules/MMM-Wallpaper
RUN npm install

# Run final install
WORKDIR /opt/mirror/MagicMirror
# OTel instrumentation deps are declared (and Renovate-bumped) in
# files/node/package.json. COPY it in and install exactly those versions so a
# bump changes a real, COPY'd build input — invalidating this layer and
# producing a new image digest — instead of editing a file the build never
# reads (which left every rebuild byte-identical, collapsing all tags onto one
# manifest digest). Installed into MagicMirror's tree because otel-init.js is
# --require'd from this WORKDIR.
COPY --chown=node:node files/node/package.json /opt/mirror/MagicMirror/otel-deps.json
RUN OTEL_PKGS="$(node -e 'const d=require("./otel-deps.json").dependencies; process.stdout.write(Object.keys(d).map(k=>k+"@"+d[k]).join(" "))')" \
 && npm install --save $OTEL_PKGS \
 && rm otel-deps.json
RUN npm install

# Create env directory for mounted config (will be a mount point)
RUN mkdir -p /opt/mirror/env

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["bash", "/opt/mirror/startup.sh"]
