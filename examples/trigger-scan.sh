#!/usr/bin/env bash
# Trigger a Scovant agent-readiness scan (+ simulation for commerce-like sites)
# from any CI or deploy step.
#
# Required env:
#   SCOVANT_TOKEN    - API token from Settings -> API tokens (scvt_...)
#   SCOVANT_SITE_ID  - your site's UUID
#
# Optional env (all recorded on the run and shown in regression reports):
#   ENVIRONMENT (e.g. production), BRANCH, COMMIT_SHA
set -euo pipefail

: "${SCOVANT_TOKEN:?set SCOVANT_TOKEN}"
: "${SCOVANT_SITE_ID:?set SCOVANT_SITE_ID}"

# Idempotency-Key makes deploy-hook retries safe: the same key within 24h
# returns the original response instead of triggering a second run.
IDEMPOTENCY_KEY="${COMMIT_SHA:-$(date +%s)}-${ENVIRONMENT:-default}"

curl -fsS -X POST "https://scovant.com/api/ci/trigger" \
  -H "Authorization: Bearer ${SCOVANT_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d "$(cat <<JSON
{
  "site_id": "${SCOVANT_SITE_ID}",
  "environment": "${ENVIRONMENT:-production}",
  "branch": "${BRANCH:-}",
  "commit_sha": "${COMMIT_SHA:-}"
}
JSON
)"

# The call returns 202 with {scan_run_id, simulation_run_ids, run_group_id, status}.
# The first run per environment establishes the baseline; every later run is
# compared against it. Regressions arrive via your configured webhooks
# (`ci.completed` fires on every compared run, `regressions.detected` only when
# something dropped) — or poll the MCP interface (stateless JSON mode) from CI.
