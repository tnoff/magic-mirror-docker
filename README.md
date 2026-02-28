# Magic Mirror Docker

Dockerized [MagicMirror](https://github.com/MagicMirrorOrg/MagicMirror) installation with OpenTelemetry instrumentation.

## Features

- **MagicMirror Core**: Latest version cloned from upstream
- **Custom Modules**: Pre-installed with MMM-BartTimes and MMM-BackgroundSlideshow
- **OpenTelemetry Integration**: Automatic instrumentation with OTLP trace export
- **Environment Variable Support**: Config files processed with `envsubst` for easy environment-based configuration
- **Custom Startup Scripts**: Support for custom initialization logic
- **Security**: Runs as non-root user (UID 1000)
- **Health Check**: Built-in `/health` endpoint with Docker `HEALTHCHECK` configured

## Usage

### Basic Example

```bash
docker run -d \
  -v /path/to/config.js:/opt/mirror/env/config.js:ro \
  -p 8080:8080 \
  your-registry/magic-mirror:latest
```

### With OpenTelemetry Configuration

```bash
docker run -d \
  -v /path/to/config.js:/opt/mirror/env/config.js:ro \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=http://your-collector:4318 \
  -e OTEL_SERVICE_NAME=magic-mirror \
  -p 8080:8080 \
  your-registry/magic-mirror:latest
```

### With Custom Startup Script

```bash
docker run -d \
  -v /path/to/config.js:/opt/mirror/env/config.js:ro \
  -v /path/to/custom-startup.sh:/opt/mirror/env/custom-startup.sh:ro \
  -p 8080:8080 \
  your-registry/magic-mirror:latest
```

## Configuration

### Required Mount

Your MagicMirror `config.js` file must be mounted at `/opt/mirror/env/config.js`.

**Important**: The container runs as user `node` (UID 1000, GID 1000). Ensure mounted files are readable by UID 1000:

```bash
# On the host
chmod 644 /path/to/config.js
```

### Environment Variable Substitution

The config file is processed with `envsubst` at startup, allowing you to use environment variables:

```javascript
// In your config.js
var config = {
    address: "${MIRROR_ADDRESS}",
    port: ${MIRROR_PORT},
    // ... rest of config
}
```

Then pass the variables at runtime:

```bash
docker run -e MIRROR_ADDRESS=0.0.0.0 -e MIRROR_PORT=8080 ...
```

### Custom Startup Script (Optional)

Place a custom bash script at `/opt/mirror/env/custom-startup.sh` to run additional initialization before MagicMirror starts:

```bash
#!/bin/bash
# Your custom initialization
echo "Running custom startup tasks..."
```

Ensure the script is readable:

```bash
chmod 755 /path/to/custom-startup.sh
```

## Health Check

The container exposes a `/health` endpoint on port 8080 that returns `{"status":"ok"}` once the MagicMirror Express server is running. Docker's `HEALTHCHECK` polls this endpoint automatically:

- **Interval**: 30s
- **Timeout**: 10s
- **Start period**: 60s (grace period for server startup)
- **Retries**: 3

You can also query it manually:

```bash
curl http://localhost:8080/health
```

## OpenTelemetry Configuration

The container includes OpenTelemetry auto-instrumentation. Configure using standard OpenTelemetry environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT`: OTLP collector endpoint (default: http://localhost:4318)
- `OTEL_SERVICE_NAME`: Service name for traces (default: auto-detected)
- `OTEL_EXPORTER_OTLP_HEADERS`: Additional headers for OTLP export
- See [OpenTelemetry documentation](https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/) for full configuration options

## Building

### Local Build

```bash
docker build -t magic-mirror .
```

### Multi-platform Build

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t magic-mirror .
```

## Included MagicMirror Modules

- **[MMM-BartTimes](https://github.com/tnoff/MMM-BartTimes)**: Display BART transit times
- **[MMM-BackgroundSlideshow](https://github.com/darickc/MMM-BackgroundSlideshow)**: Background image slideshow

## License

See [LICENSE](LICENSE) file.
