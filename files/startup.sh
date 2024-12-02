#!/bin/bash

if [ -f "/opt/mirror/env/custom-startup.sh" ]; then
    chmod +x /opt/mirror/env/custom-startup.sh
    bash /opt/mirror/env/custom-startup.sh
fi

cp /opt/mirror/env/config.js /opt/mirror/MagicMirror/config/
cd /opt/mirror/MagicMirror/
npm run server
