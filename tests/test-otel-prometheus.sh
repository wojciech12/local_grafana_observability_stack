#!/bin/bash

# Test Prometheus integration via Alloy by sending sample metrics data

echo "Testing Prometheus integration..."

# Generate current timestamp
CURRENT_TIME=$(date +%s)000000000

echo "Sending metrics at timestamp: $CURRENT_TIME"

# Test 1: Send metrics data via Alloy (OTLP HTTP)
echo "1. Testing OTLP metrics ingestion via Alloy..."
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{
    "resourceMetrics": [
      {
        "resource": {
          "attributes": [
            {
              "key": "service.name",
              "value": {
                "stringValue": "my-app-prom-test"
              }
            },
            {
              "key": "service.version",
              "value": {
                "stringValue": "1.0.0"
              }
            }
          ]
        },
        "scopeMetrics": [
          {
            "scope": {
              "name": "test-meter"
            },
            "metrics": [
              {
                "name": "test_counter_total",
                "description": "Test counter metric",
                "unit": "1",
                "sum": {
                  "dataPoints": [
                    {
                      "attributes": [
                        {
                          "key": "test.type",
                          "value": {
                            "stringValue": "integration"
                          }
                        },
                        {
                          "key": "operation.name",
                          "value": {
                            "stringValue": "test-operation"
                          }
                        }
                      ],
                      "timeUnixNano": "'$CURRENT_TIME'",
                      "asInt": "42"
                    }
                  ],
                  "aggregationTemporality": "AGGREGATION_TEMPORALITY_CUMULATIVE",
                  "isMonotonic": true
                }
              },
              {
                "name": "test_gauge",
                "description": "Test gauge metric",
                "unit": "bytes",
                "gauge": {
                  "dataPoints": [
                    {
                      "attributes": [
                        {
                          "key": "test.type",
                          "value": {
                            "stringValue": "integration"
                          }
                        }
                      ],
                      "timeUnixNano": "'$CURRENT_TIME'",
                      "asDouble": 123.45
                    }
                  ]
                }
              },
              {
                "name": "test_histogram",
                "description": "Test histogram metric",
                "unit": "s",
                "histogram": {
                  "dataPoints": [
                    {
                      "attributes": [
                        {
                          "key": "test.type",
                          "value": {
                            "stringValue": "integration"
                          }
                        }
                      ],
                      "timeUnixNano": "'$CURRENT_TIME'",
                      "count": "10",
                      "sum": 15.5,
                      "bucketCounts": ["2", "3", "4", "1"],
                      "explicitBounds": [0.1, 0.5, 1.0]
                    }
                  ],
                  "aggregationTemporality": "AGGREGATION_TEMPORALITY_CUMULATIVE"
                }
              }
            ]
          }
        ]
      }
    ]
  }'

echo -e "\n"

# Wait a moment for ingestion
echo "Waiting 5 seconds for metrics ingestion..."
sleep 5

# Test 2: Query the specific metrics from Prometheus
echo "2. Querying test counter from Prometheus..."
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=test_counter_total{service_name="my-app-prom-test"}' | jq '.data.result'

echo -e "\n"

# Test 3: Query gauge metric
echo "3. Querying test gauge from Prometheus..."
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=test_gauge{service_name="my-app-prom-test"}' | jq '.data.result'

echo -e "\n"

# Test 4: Query histogram metric
echo "4. Querying test histogram from Prometheus..."
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query=test_histogram_bucket{service_name="my-app-prom-test"}' | jq '.data.result'

echo -e "\n"

# Test 5: Check all metrics with my-app-prom-test service
echo "5. Checking all metrics for my-app-prom-test service..."
curl -s -G "http://localhost:9090/api/v1/query" \
  --data-urlencode 'query={service_name="my-app-prom-test"}' | jq '.data.result[] | {metric: .metric.__name__, value: .value[1]}'

echo -e "\n"

# Test 6: Check if metrics are being scraped by looking at targets
echo "6. Checking Prometheus targets..."
curl -s "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | select(.labels.job == "alloy") | {job: .labels.job, health: .health, lastError: .lastError}'

echo -e "\n\nTest completed!"
echo "- Check Grafana at http://localhost:3000 to view metrics"
echo "- Check Prometheus directly at http://localhost:9090/graph"
echo "- Query examples:"
echo "  - test_counter_total{service_name=\"my-app-prom-test\"}"
echo "  - test_gauge{service_name=\"my-app-prom-test\"}"
echo "  - test_histogram_bucket{service_name=\"my-app-prom-test\"}"