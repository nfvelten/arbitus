# Changelog

## [0.5.0] — 2026-03-28

### Added
- **Response filtering** in stdio transport: block patterns now applied to all upstream responses, not just HTTP
- **Configurable circuit breaker**: `circuit_breaker.threshold` and `circuit_breaker.recovery_secs` in `gateway.yml`
- **Key-based agent identity**: `X-Api-Key` header maps directly to an agent (via reverse lookup in `LiveConfig`), overriding `clientInfo.name`
- **Audit log rotation**: `max_entries` and `max_age_days` options for `sqlite` audit backend
- **`/health` endpoint**: returns `{"status":"ok","version":"0.5.0"}`
- **Config validation at startup**: validates regexes, upstream references, TLS file existence, circuit breaker threshold
- **SIGUSR1 hot-reload**: immediate config reload on `SIGUSR1`; 30-second polling as fallback
- **Test coverage**: 42 HTTP integration tests, 16 stdio integration tests

### Changed
- `LiveConfig::new()` now precomputes the `api_key → agent_name` reverse map for O(1) key lookup
- `do_reload()` extracted as a helper to avoid duplication between signal and timer paths

---

## [0.4.0] — 2026-03-27

### Added
- **API key authentication**: `api_key` field per agent in config; middleware returns 401 on mismatch
- **Response filtering**: HTTP responses checked against `block_patterns`; replaced with error on match
- **Config hot-reload**: config file polled every 30 seconds; changes applied without restart via `watch::channel`
- **`FanoutAudit`**: fan-out audit backend that writes to multiple backends simultaneously
- **Circuit breaker** in `HttpUpstream`: opens after N consecutive failures, recovers after timeout
- **Per-tool rate limits**: `tool_rate_limits` map per agent (e.g., `echo: 2` — max 2 calls/min to that tool)
- **SSE proxy**: `GET /mcp` proxies upstream SSE stream with per-event response filtering
- **`DELETE /mcp`**: session invalidation endpoint; returns 204 on success, 404 if not found
- **Prometheus metrics endpoint** (`/metrics`): request counts, blocked counts, latency histograms
- **Named upstreams**: `upstreams:` map in config; agents can route to different upstream servers
- **TLS support**: optional `tls.cert` / `tls.key` in HTTP transport config

---

## [0.3.0] — 2026-03-26

### Added
- **`DELETE /mcp`** session invalidation
- **Webhook audit backend**: POSTs JSON audit entries to a configurable URL with optional Bearer token
- **`FanoutAudit` skeleton**: multiple audit backends wired together
- **Session TTL**: configurable `session_ttl_secs` in HTTP transport

---

## [0.2.0] — 2026-03-25

### Added
- **HTTP transport** (`axum`) with MCP session management (`Mcp-Session-Id` header)
- **SQLite audit log** with async worker task
- **Middleware pipeline**: auth, rate limit, payload filter — composable and ordered
- **`tools/list` filtering**: per-agent `allowed_tools` / `denied_tools` applied to upstream responses
- **Stdio transport**: wraps any MCP server process, intercepts JSON-RPC on stdin/stdout
- **`x-agent-id` fallback** for clients that skip session management

---

## [0.1.0] — 2026-03-24

### Added
- Initial implementation: JSON-RPC 2.0 proxy with basic allow/deny tool filtering
- YAML config (`gateway.yml`) with agents, rules, and transport sections
- Stdout audit backend
- HTTP upstream with `reqwest`
