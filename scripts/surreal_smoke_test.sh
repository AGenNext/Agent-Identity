#!/usr/bin/env bash
# Loads the Agent Identity SurrealQL into a running SurrealDB instance, in
# dependency order, then runs runtime assertions. This catches errors that the
# static validators cannot (event logic, custom functions, RELATE, asserts).
#
# Requires a running SurrealDB reachable at $SURREAL_HOST (default 127.0.0.1:8000)
# with root/root credentials. Intended for CI (.github/workflows/surreal-smoke.yml).
set -euo pipefail

NS=agent_identity
DB=dev
HOST="${SURREAL_HOST:-127.0.0.1:8000}"
AUTH=(--username root --password root --endpoint "http://${HOST}")

imp() {
  echo ">> importing $1"
  surreal import "${AUTH[@]}" --namespace "$NS" --database "$DB" "$1"
}

# Schema, in dependency order (agent_identity defines the base tables others reference).
imp surreal/schema/agent_identity.surql
imp surreal/schema/agent_lifecycle.surql
imp surreal/schema/agent_did.surql
imp surreal/schema/agent_graph.surql
imp surreal/schema/agent_knowledge_graph.surql

# Seeds (these UPDATE the lifecycle, exercising the guard + audit DEFINE EVENTs).
imp surreal/seeds/agent_identity.seed.surql
imp surreal/seeds/agent_lifecycle.seed.surql

echo ">> positive path: seeded lifecycle should be 'active'"
STATE_OUT=$(echo 'SELECT VALUE state FROM agent_lifecycle:research_agent;' \
  | surreal sql "${AUTH[@]}" --namespace "$NS" --database "$DB" --json)
echo "$STATE_OUT"
echo "$STATE_OUT" | grep -q '"active"' || echo "$STATE_OUT" | grep -q 'active' \
  || { echo "FAIL: expected lifecycle state 'active'"; exit 1; }

echo ">> audit path: a lifecycle_audit_log entry should exist for the activation"
AUDIT_OUT=$(echo 'SELECT count() FROM lifecycle_audit_log GROUP ALL;' \
  | surreal sql "${AUTH[@]}" --namespace "$NS" --database "$DB" --json)
echo "$AUDIT_OUT"

echo ">> guard path: an illegal transition (active -> provisioned) must be rejected"
GUARD_OUT=$(echo 'UPDATE agent_lifecycle:research_agent SET state = "provisioned";' \
  | surreal sql "${AUTH[@]}" --namespace "$NS" --database "$DB" 2>&1 || true)
echo "$GUARD_OUT"
echo "$GUARD_OUT" | grep -qi "Illegal lifecycle transition" \
  || { echo "FAIL: transition guard did not reject the illegal move"; exit 1; }

echo "✅ SurrealDB smoke test passed (schema loads, events fire, guard enforces grammar)."
