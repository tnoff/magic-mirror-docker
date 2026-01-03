FROM node:25-bookworm

# Setup basics
RUN apt-get update && apt-get install -y git gettext

# Setup mirror
RUN mkdir -p /opt/mirror
RUN git clone https://github.com/MagicMirrorOrg/MagicMirror /opt/mirror/MagicMirror
RUN chown -R node:node /opt/mirror
COPY files/node/otel-init.js /opt/mirror/MagicMirror/
COPY files/startup.sh /opt/mirror
RUN chmod +x /opt/mirror/startup.sh

USER node

RUN git clone https://github.com/tnoff/MMM-BartTimes.git /opt/mirror/MagicMirror/modules/MMM-BartTimes
RUN git clone https://github.com/darickc/MMM-BackgroundSlideshow.git /opt/mirror/MagicMirror/modules/MMM-BackgroundSlideshow
# Add in instrumentation files

RUN sed -i.bak 's|"server": "node ./serveronly"|"server": "node --require ./otel-init.js serveronly"|' /opt/mirror/MagicMirror/package.json
# Run install on custom modules
WORKDIR /opt/mirror/MagicMirror/modules/MMM-BartTimes
RUN npm install
WORKDIR /opt/mirror/MagicMirror/modules/MMM-BackgroundSlideshow
RUN npm install

# Run final install
WORKDIR /opt/mirror/MagicMirror
RUN npm install --save @opentelemetry/auto-instrumentations-node @opentelemetry/sdk-node @opentelemetry/sdk-trace-node
RUN npm install

# Create env directory for mounted config (will be a mount point)
RUN mkdir -p /opt/mirror/env

CMD ["bash", "/opt/mirror/startup.sh"]
