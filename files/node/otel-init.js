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

const sdk = new NodeSDK({
  resourceAttributes: {
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'unknown_service',
    ...customAttributes,
  },
  traceExporter: new OTLPTraceExporter(),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();