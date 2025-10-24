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

# Set up provisioning directory
export GF_PATHS_PROVISIONING=/etc/grafana/provisioning
mkdir -p $GF_PATHS_PROVISIONING/datasources
mkdir -p $GF_PATHS_PROVISIONING/dashboards

# Setup provisioning based on environment variables
setup_provisioning() {
  # Setup datasource provisioning
  if [ ! -z "$OSC_DATASOURCES" ]; then
    echo "apiVersion: 1" > $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
    echo "datasources:" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
    
    # Use a temporary variable to avoid subshell issues
    OLDIFS="$IFS"
    IFS='|'
    for datasource in $OSC_DATASOURCES; do
      if [ ! -z "$datasource" ]; then
        # Parse datasource format: name:type:url[;user;password]
        # First extract name and type
        name=$(echo "$datasource" | cut -d':' -f1)
        type=$(echo "$datasource" | cut -d':' -f2)
        
        # Extract the rest (url and optional auth)
        rest=$(echo "$datasource" | cut -d':' -f3-)
        
        # Check if there are semicolons for auth (name:type:url;user;password)
        if echo "$rest" | grep -q ';'; then
          url=$(echo "$rest" | cut -d';' -f1)
          user=$(echo "$rest" | cut -d';' -f2)
          password=$(echo "$rest" | cut -d';' -f3)
        else
          url="$rest"
          user=""
          password=""
        fi
        
        # Debug logging
        echo "DEBUG: Parsing datasource: $datasource"
        echo "DEBUG: name='$name' type='$type' url='$url' user='$user' password='$password'"
        
        # Generate a UID based on the name (replace spaces/special chars with underscores)
        uid=$(echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_')
        echo "DEBUG: Generated uid='$uid'"
        
        echo "  - name: \"$name\"" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        echo "    type: $type" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        echo "    uid: $uid" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        echo "    url: $url" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        echo "    access: proxy" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        echo "    orgId: 1" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        echo "    isDefault: false" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        
        if [ ! -z "$user" ] && [ ! -z "$password" ]; then
          echo "    basicAuth: true" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
          echo "    basicAuthUser: $user" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
          echo "    secureJsonData:" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
          echo "      basicAuthPassword: $password" >> $GF_PATHS_PROVISIONING/datasources/osc-datasources.yml
        fi
      fi
    done
    IFS="$OLDIFS"
  fi

  # Setup dashboard provisioning
  if [ ! -z "$OSC_DASHBOARD_URLS" ]; then
    mkdir -p /var/lib/grafana/dashboards
    
    cat > $GF_PATHS_PROVISIONING/dashboards/osc-dashboards.yml << EOF
apiVersion: 1
providers:
  - name: osc-dashboards
    type: file
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
EOF

    # Download dashboards
    echo "$OSC_DASHBOARD_URLS" | tr ',' '\n' | while read -r dashboard_url; do
      if [ ! -z "$dashboard_url" ]; then
        dashboard_name=$(basename "$dashboard_url" .json)
        echo "Downloading dashboard: $dashboard_name"
        curl -s -o "/var/lib/grafana/dashboards/${dashboard_name}.json" "$dashboard_url"
      fi
    done
  fi
}

# Run provisioning setup
setup_provisioning

exec /run.sh
