#!/usr/bin/env bash
set -euo pipefail

# Checks the PrometheusRules in ../rules and unit-tests them with promtool, against synthetic series, so the alert logic
# is verified without waiting for real traffic or a real failure. Needs Docker.
#
# promtool reads plain rule files, not PrometheusRule resources. Each file here has `spec:` as its last top-level key, so
# the plain file is everything under it, dedented by one level.
#
# Usage:  observability/tests/run.sh
# Override the promtool image (default: prom/prometheus) with PROMTOOL_IMAGE; the cluster runs Prometheus v3.14.0.

PROMTOOL_IMAGE="${PROMTOOL_IMAGE:-prom/prometheus}"

cd "$(dirname "$0")/.."

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

for rules in rules/*.yaml; do
  sed -n '/^spec:/,$p' "${rules}" | tail -n +2 | sed 's/^  //' > "${work}/$(basename "${rules}")"
done
cp tests/*_test.yaml "${work}/"

promtool() {
  docker run --rm -v "${work}":/rules --entrypoint promtool "${PROMTOOL_IMAGE}" "$@"
}

echo "promtool: $(docker run --rm --entrypoint promtool "${PROMTOOL_IMAGE}" --version | head -1)"
echo
echo "== check rules"
promtool check rules /rules/service-alerts.yaml /rules/pipeline-alerts.yaml
echo
echo "== test rules"
promtool test rules /rules/alerts_test.yaml
