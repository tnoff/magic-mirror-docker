FROM node:25-bookworm

# Setup basics
# Update to latest for security fixes
RUN apt-get update && \
    apt-get install -y gettext && \
    apt-get upgrade -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# renovate: datasource=git-refs depName=MagicMirror packageName=https://github.com/MagicMirrorOrg/MagicMirror currentValue=master
ARG MAGICMIRROR_REF=fb41d24ef522e91e802e2a623ff6afbddeb3c9d8
# renovate: datasource=git-refs depName=MMM-BartTimes packageName=https://gitlab.com/tnoff-projects/MMM-BartTimes currentValue=master
ARG MMM_BARTTIMES_REF=b2c527d5d638d75c4d8ebfe1dcfea7baa3c37ebe
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
ADD --chown=node:node https://gitlab.com/tnoff-projects/MMM-BartTimes/-/archive/${MMM_BARTTIMES_REF}/MMM-BartTimes-${MMM_BARTTIMES_REF}.tar.gz /tmp/bart.tgz
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
RUN npm install
WORKDIR /opt/mirror/MagicMirror/modules/MMM-Wallpaper
RUN npm install

# Run final install
WORKDIR /opt/mirror/MagicMirror
RUN npm install --save @opentelemetry/auto-instrumentations-node @opentelemetry/sdk-node @opentelemetry/sdk-trace-node
RUN npm install

# Create env directory for mounted config (will be a mount point)
RUN mkdir -p /opt/mirror/env

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["bash", "/opt/mirror/startup.sh"]
