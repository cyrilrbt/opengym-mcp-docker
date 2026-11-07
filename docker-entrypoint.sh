#!/bin/sh
set -eu
if [ -z "${SUPERGATEWAY_API_KEY:-}" ]; then
  echo >&2 'ERROR: SUPERGATEWAY_API_KEY is required; refusing to start unauthenticated.'
  exit 1
fi
exec supergateway \
  --stdio 'node /opt/opengym/mcp/src/index.js' \
  --outputTransport streamableHttp \
  --stateful \
  --port 8000 \
  --host 0.0.0.0 \
  --healthEndpoint /healthz
