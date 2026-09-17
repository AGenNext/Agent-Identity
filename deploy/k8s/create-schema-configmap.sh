#!/usr/bin/env bash
# Creates the `agent-identity-schema` ConfigMap from the repo's SurrealQL files.
# Run from the repository root. The schema-load Job mounts this ConfigMap.
set -euo pipefail

NS="${1:-agent-identity}"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NS" create configmap agent-identity-schema \
  --from-file=surreal/schema \
  --from-file=surreal/seeds \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ ConfigMap 'agent-identity-schema' applied in namespace '$NS'."
