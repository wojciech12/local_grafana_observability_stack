# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a complete Grafana observability stack designed for monitoring CLI applications with OpenTelemetry integration. The stack includes distributed tracing (Tempo), metrics (Prometheus), logs (Loki), and visualization (Grafana) with Grafana Alloy as the OTLP collector. All comms to Grafana stack goes through Alloy.

## Common Commands

### Stack Management
```bash
# Start the complete monitoring stack
docker compose up -d

# Stop the stack
docker compose down

# Remove all data volumes
docker compose down -v

# Check running services
docker compose ps

# View service logs
docker compose logs <service-name>

# Restart specific service
docker compose restart <service-name>
```

### Testing
```bash
# Test Loki integration with sample log data via Alloy (OTel gateway)
./tests/test-otel-loki.sh
```

## Architecture Overview

The stack follows a standard observability pattern with OTLP ingestion:

1. **Grafana Alloy** (ports 4317/4318) - Receives OTLP telemetry from CLI applications
2. **Tempo** (port 3200) - Distributed tracing backend with span metrics generation
3. **Prometheus** (port 9090) - Metrics storage with exemplar support and native histograms
4. **Loki** (port 3100) - Log aggregation and storage
5. **Grafana** (port 3000) - Unified visualization dashboard

## Key Configuration Files

- `config.alloy` - River language config for OTLP ingestion and routing
- `tempo.yml` - Tempo configuration with metrics generator and service graphs
- `prometheus.yml` - Prometheus scraping config for stack components
- `grafana/provisioning/datasources/datasources.yml` - Auto-configured datasources

## Service Endpoints

| Service | Port | Purpose |
|---------|------|---------|
| Grafana | 3000 | Dashboards (admin/admin) |
| Prometheus | 9090 | Metrics queries |
| Tempo | 3200 | Trace queries |
| Loki | 3100 | Log queries |
| Alloy | 12345 | Web UI and status |
| Alloy OTLP | 4317/4318 | gRPC/HTTP telemetry ingestion |

## CLI Integration

Configure applications to send telemetry to Alloy:
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

## Data Flow

App → Alloy (OTLP) → Tempo/Prometheus/Loki → Grafana

The stack includes:
- Service graphs generated from traces
- Span metrics (RED metrics) from trace data
- Exemplar links between metrics and traces
- Centralized log aggregation with OTLP support
- Self-monitoring of all stack components

## Troubleshooting

Common issues:
- Permission errors: Ensure init container ran successfully
- Connection failures: Check service dependencies and startup order
- Missing telemetry: Verify OTLP endpoints are accessible
- Configuration errors: Check Alloy web UI at http://localhost:12345