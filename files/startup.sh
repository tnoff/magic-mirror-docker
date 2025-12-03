#!/bin/bash

if [ -f "/opt/mirror/env/custom-startup.sh" ]; then
    chmod +x /opt/mirror/env/custom-startup.sh
    bash /opt/mirror/env/custom-startup.sh
fi

envsubst < /opt/mirror/env/config.js > /opt/mirror/MagicMirror/config/config.js
cd /opt/mirror/MagicMirror/
npm run server
