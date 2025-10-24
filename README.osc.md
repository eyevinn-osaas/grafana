# Grafana OSC Configuration

This document describes the OSC-specific configuration options for the Grafana container.

## Environment Variables

### OSC_HOSTNAME
Sets the Grafana server root URL for external access.
- **Format**: `hostname` or `hostname:port`
- **Example**: `OSC_HOSTNAME="grafana.example.com"`
- **Default**: `http://localhost:3000`

### OSC_ALLOW_EMBED_ORIGINS
Enables embedding and CORS for specified origins.
- **Format**: Comma-separated list of origins
- **Example**: `OSC_ALLOW_EMBED_ORIGINS="https://app.example.com,https://dashboard.example.com"`
- **Effect**: Sets `GF_SECURITY_ALLOW_EMBEDDING=true`, `GF_CORS_ENABLED=true`, and `GF_CORS_ALLOWED_ORIGINS`

### OSC_DATASOURCES
Configures datasources to be automatically provisioned at startup.
- **Format**: `name:type:url[;user;password]|name:type:url[;user;password]|...`
- **Delimiter**: `|` separates multiple datasources
- **Auth delimiter**: `;` separates user and password (optional)

#### Examples:
```bash
# Single datasource without authentication
OSC_DATASOURCES="prometheus:prometheus:http://prometheus:9090"

# Single datasource with authentication
OSC_DATASOURCES="influx:influxdb:http://influxdb:8086;admin;secret"

# Multiple datasources
OSC_DATASOURCES="prometheus:prometheus:http://prometheus:9090|influx:influxdb:http://influxdb:8086;admin;secret"
```

#### Supported Datasource Types:
- `prometheus` - Prometheus
- `influxdb` - InfluxDB
- `mysql` - MySQL
- `postgres` - PostgreSQL
- `graphite` - Graphite
- `elasticsearch` - Elasticsearch
- `opentsdb` - OpenTSDB
- `cloudwatch` - AWS CloudWatch
- And many more...

### OSC_DASHBOARD_URLS
Downloads and provisions dashboard JSON files from URLs.
- **Format**: Comma-separated list of URLs
- **Example**: `OSC_DASHBOARD_URLS="https://example.com/dashboard1.json,https://example.com/dashboard2.json"`

#### Dashboard URL Requirements:
- Must be publicly accessible HTTP/HTTPS URLs
- Must return valid Grafana dashboard JSON format
- Dashboards are downloaded at container startup

## Container Configuration

### Ports
- **Internal Port**: 8080 (Grafana HTTP port)
- **External Port**: Configurable via Docker port mapping

### Volumes
- `/etc/grafana/provisioning` - Provisioning configuration directory
- `/var/lib/grafana/dashboards` - Dashboard files directory
- `/var/lib/grafana` - Grafana data directory

## Usage Examples

### Basic Setup
```bash
docker run -d \
  -p 8080:8080 \
  -e OSC_HOSTNAME="grafana.local" \
  grafana:osc
```

### With Datasources
```bash
docker run -d \
  -p 8080:8080 \
  -e OSC_HOSTNAME="grafana.local" \
  -e OSC_DATASOURCES="prometheus:prometheus:http://prometheus:9090|mysql:mysql:mysql://db:3306;dbuser;dbpass" \
  grafana:osc
```

### With Dashboards
```bash
docker run -d \
  -p 8080:8080 \
  -e OSC_HOSTNAME="grafana.local" \
  -e OSC_DATASOURCES="prometheus:prometheus:http://prometheus:9090" \
  -e OSC_DASHBOARD_URLS="https://example.com/node-exporter.json,https://example.com/mysql.json" \
  grafana:osc
```

### With Embedding Enabled
```bash
docker run -d \
  -p 8080:8080 \
  -e OSC_HOSTNAME="grafana.local" \
  -e OSC_ALLOW_EMBED_ORIGINS="https://myapp.com" \
  grafana:osc
```

## Provisioning

The container automatically sets up Grafana provisioning based on the environment variables:

### Datasource Provisioning
- Creates `/etc/grafana/provisioning/datasources/osc-datasources.yml`
- Each datasource gets a unique UID based on its name
- All datasources are assigned to organization ID 1
- Proxy access mode is used by default

### Dashboard Provisioning
- Creates `/etc/grafana/provisioning/dashboards/osc-dashboards.yml`
- Downloads dashboard JSON files to `/var/lib/grafana/dashboards/`
- Dashboard provider checks for updates every 30 seconds

## Troubleshooting

### Debug Mode
The container outputs debug information about datasource parsing. Look for lines starting with `DEBUG:` in the container logs.

### Common Issues

1. **Datasource provisioning errors**: Check that the datasource format is correct and URLs are accessible
2. **Dashboard download failures**: Ensure dashboard URLs are publicly accessible and return valid JSON
3. **Embedding not working**: Verify `OSC_ALLOW_EMBED_ORIGINS` includes the correct origins

### Logs
```bash
# View container logs
docker logs <container_id>

# Follow logs in real-time
docker logs -f <container_id>
```