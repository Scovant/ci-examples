# Agent-readiness CI with Scovant

Example CI configurations for keeping a website agent-ready across deploys — a free,
run-it-yourself tier built on the open-source scanner, and a paid tier that adds real
AI-agent simulations and baseline regression detection through
[Scovant](https://scovant.com/?utm_source=scovant-ci-examples-readme).

> Agent-readiness is a regression, not a score. A passing score on deploy day tells you
> what your site declares. Whether AI agents can still complete real flows after your
> latest change is something you want to know in CI, not after they start failing in
> production.

## Tier 1 — free: gate on Scovant Core (open source)

[Scovant Core](https://github.com/Scovant/scovant-core) is a passive, evidence-first
scanner (CLI, GitHub Action, MCP server). It needs no account and no token; it runs
inside your pipeline and fails the step when the Core score drops below a floor you set
or when a check FAILs.

- [`.github/workflows/scovant-core-gate.yml`](.github/workflows/scovant-core-gate.yml) —
  the Action as a PR / deploy gate (`min-core-score`, `fail-on`, private-staging flags).
- One-off from any shell: `pipx run scovant-core scan https://your-site.example`
  (or `pip install scovant-core`). Exit codes are documented in the Core README.
- Claude Code: `/plugin marketplace add Scovant/scovant-core` →
  `/plugin install scovant@scovant`, then `/scovant:ci` writes this same workflow into
  your repo.

What Core does **not** do: crawl your whole site, render JavaScript, run an AI agent
through a checkout, or compare deploys against a baseline. That is the paid tier.

## Tier 2 — Scovant Cloud: simulations + regression detection

Scovant Cloud crawls the site, scores it against the full
[rule catalog](https://scovant.com/rules), runs **real AI agents** (a multi-model
catalog of fifteen LLM agents) through purchase and booking flows, and compares every
CI run against the environment's baseline — regressions arrive as webhooks.

- [`examples/trigger-scan.sh`](examples/trigger-scan.sh) — trigger a scan + simulation
  from any CI or deploy step with plain `curl` (idempotent on retries).
- [`.github/workflows/scovant-ci.yml`](.github/workflows/scovant-ci.yml) — the same as
  a GitHub Actions job.

`POST /api/ci/trigger` returns 202 with `{scan_run_id, simulation_run_ids,
run_group_id, status}`. The first run per environment establishes the baseline; every
later run is compared against it. `ci.completed` fires on every compared run,
`regressions.detected` only when a score or a simulation outcome dropped. `ci.completed`
carries an `attribution` block (`SITE_DELTA` / `MODEL_DELTA` / `HARNESS_DELTA` /
`MIXED_DELTA` / `UNKNOWN_DELTA` plus `control_quality`) — `regressions.detected` does
not; read attribution from the completion event. It says whether the two runs
differed in the scoring model or the scanner build rather than in your site — a
`MODEL_DELTA` or `HARNESS_DELTA` is not a change you shipped. Results can
also be polled from CI through the MCP interface (stateless JSON mode) — see
[scovant.com/.well-known/mcp.json](https://scovant.com/.well-known/mcp.json).

### Getting a token

Create an API token (`scvt_…`) in **Settings → API tokens** on
[scovant.com](https://scovant.com) and store it as a CI secret (`SCOVANT_TOKEN`). Your
site's UUID is in the site page URL, or via the MCP `list_sites` tool.

## Using both

A common setup: the Core gate on every pull request (fast, free, no external state),
the Cloud trigger after each production deploy (the slow, stateful comparison that
knows what your site looked like last week).

## Links

- [Scovant](https://scovant.com/?utm_source=scovant-ci-examples-readme) · [Pricing](https://scovant.com/pricing) · [Docs](https://scovant.com/docs)
- [Rule catalog](https://scovant.com/rules) · [Scoring methodology](https://scovant.com/scoring)
- [Scovant Core](https://github.com/Scovant/scovant-core) · [Check spec](https://github.com/Scovant/agent-readiness-checks) · [Readiness checklist](https://github.com/Scovant/agent-readiness)

## License

[CC BY 4.0](LICENSE) — reuse freely with attribution to [Scovant](https://scovant.com).
