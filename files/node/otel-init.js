'use strict';

const { NodeSDK } = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { SemanticResourceAttributes } = require("@opentelemetry/semantic-conventions");

// Parse custom resource attributes from environment variable
function parseResourceAttributes(attrString) {
  const attributes = {};
  if (!attrString) return attributes;

  const pairs = attrString.split(',');
  for (const pair of pairs) {
    const [key, value] = pair.split('=').map(s => s.trim());
    if (key && value) {
      attributes[key] = value;
    }
  }
  return attributes;
}

const customAttributes = parseResourceAttributes(process.env.OTEL_RESOURCE_ATTRIBUTES);

// Paths whose incoming requests are not worth a trace. `/health` is hit by the
// kubelet only (readiness every 10s + liveness every 30s, see
// apps/mirror/*/mirror-app.yaml in docker-apps) and by the Dockerfile
// HEALTHCHECK when run under plain Docker. Nobody has ever opened one of those
// traces, and there are ~166 of them for every real page view.
const UNTRACED_PATHS = new Set(['/health']);

const sdk = new NodeSDK({
  resourceAttributes: {
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'unknown_service',
    ...customAttributes,
  },
  traceExporter: new OTLPTraceExporter(),
  instrumentations: [getNodeAutoInstrumentations({
    // MagicMirror's server is Express 5, which routes through the standalone
    // `router` package (2.2.0). The auto-instrumentation set ships an
    // instrumentation for BOTH, and each one traces the same middleware chain
    // independently — so every request produced two parallel sets of
    // `middleware - *` / `request handler - *` spans, one tagged `express.*`
    // and one tagged `router.*`, describing the identical call. Turning the
    // router one off halves the span count per request and loses nothing: the
    // express spans carry the same names plus the resolved route.
    //
    // Keep instrumentation-express ENABLED. It is what names the server span
    // after the matched route — with it off the span degrades from `GET /` to
    // a bare `GET`, which is the same unrouted-span problem that made
    // eastbay-website's span_names unbounded.
    '@opentelemetry/instrumentation-router': { enabled: false },

    // Skipping a request here suppresses its whole subtree, not just the
    // server span: instrumentation-express only creates middleware spans
    // inside an active HTTP span, so with no span to parent them it emits
    // nothing. Verified against these exact package versions — a /health
    // request goes from 8 spans to 0, with no orphaned middleware spans left
    // behind.
    '@opentelemetry/instrumentation-http': {
      ignoreIncomingRequestHook: (request) => {
        const path = (request.url || '').split('?')[0];
        return UNTRACED_PATHS.has(path);
      },
    },
  })],
});

sdk.start();