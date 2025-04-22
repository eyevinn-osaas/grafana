#!/bin/sh
if [ ! -z "$OSC_HOSTNAME" ]; then
  export GF_SERVER_ROOT_URL="https://$OSC_HOSTNAME"
else
  export GF_SERVER_ROOT_URL="http://localhost:3000"
fi
echo "server-root-url: $GF_SERVER_ROOT_URL"

exec /run.sh
