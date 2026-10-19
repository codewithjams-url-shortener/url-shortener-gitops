# observability

Grafana dashboards and Prometheus alert rules for the three services, synced by the `observability` Application in
`apps/platform/`. They live in Git because Grafana and Prometheus have no persistent volume: anything made in the Grafana UI is
lost when its pod is replaced (which happens whenever the chart's secret checksum changes).

| Path | What it is |
|---|---|
| `dashboards/services-overview.json` | Per-service HTTP traffic, 5xx share, latency and JVM health, with a `Service` variable. |
| `dashboards/click-pipeline.json` | The redirect cache hit ratio, DynamoDB throttling, the Links stream consumers and the SQS click event consumer. |
| `rules/service-alerts.yaml` | `ServiceDown`, and `ServiceHttp5xxRateHigh` (mirrors the CloudWatch alarm that rolls back an AppConfig deployment). |
| `rules/pipeline-alerts.yaml` | Alerts for the click event consumer, the Links stream consumers, the redirect cache and DynamoDB throttling. |
| `tests/` | promtool unit tests for the rules. |
| `kustomization.yaml` | Turns each dashboard JSON file into a ConfigMap labelled `grafana_dashboard=1`, which Grafana's sidecar loads. |

This directory sits outside `apps/` on purpose: `root` syncs `apps/` recursively and would apply these a second time, before the
CRDs they need exist.

## Changing a dashboard
Edit the JSON file here (or build the change in Grafana, then use *Export > Export as JSON* and paste it over the file), commit, and
let ArgoCD sync it. The sidecar reloads it within a minute. A change made only in the UI is lost.

The panels are written for these Prometheus names, so a metric renamed in a service has to be renamed here too: `http_server_requests_*`,
`jvm_*`, `process_cpu_usage`, `cache_lookup_total`, `dynamodb_throttle_count_total`, `streams_consumer_*` and `sqs_consumer_*`. The
click pipeline panels stay empty until the services run images that publish them.

## Testing the alert rules
```sh
observability/tests/run.sh
```
Needs Docker. It runs `promtool check rules` and then the unit tests in `tests/alerts_test.yaml`, which feed each alert synthetic series
and check that it fires when it should and stays quiet when it should not. Add a case there with every new or changed alert.

## Thresholds
The alert thresholds are starting points for a small local system, not measured baselines. Tune them once real traffic is flowing.
