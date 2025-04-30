#!/bin/sh
if [ ! -z "$OSC_HOSTNAME" ]; then
  export GF_SERVER_ROOT_URL="https://$OSC_HOSTNAME"
else
  export GF_SERVER_ROOT_URL="http://localhost:3000"
fi
echo "server-root-url: $GF_SERVER_ROOT_URL"
export GF_SERVER_HTTP_PORT=8080

if [ ! -z "$OSC_ALLOW_EMBED_ORIGINS" ]; then
  export GF_SECURITY_ALLOW_EMBEDDING=true
  export GF_CORS_ENABLED=true
  export GF_CORS_ALLOWED_ORIGINS=$OSC_EMBED_ORIGINS
fi
# export GF_AUTH_ANONYMOUS_ENABLED=true

exec /run.sh
