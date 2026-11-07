FROM node:22-alpine

ARG OPENGYM_REF=v1.4.4
ARG SUPERGATEWAY_VERSION=4.2.1
RUN apk add --no-cache git ca-certificates \
    && npm install --global "supergateway@${SUPERGATEWAY_VERSION}" \
    && git clone --filter=blob:none --depth 1 --branch "${OPENGYM_REF}" \
       https://github.com/DuarteSantos8/openGym.git /opt/opengym \
    && cd /opt/opengym/mcp \
    && if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi \
    && apk del git \
    && npm cache clean --force

ENV NODE_ENV=production \
    OPENGYM_DATA=/opengym-data
WORKDIR /opt/opengym
EXPOSE 8000
# The upstream server is stdio-only. Supergateway publishes Streamable HTTP at /mcp.
# Require SUPERGATEWAY_API_KEY at runtime; see docker-entrypoint.sh.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
