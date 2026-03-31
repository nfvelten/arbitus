# Changelog

## [0.7.0] — 2026-03-30

### Added
- **Schema validation middleware**: `SchemaValidationMiddleware` validates `tools/call` arguments against the `inputSchema` from `tools/list`; invalid args are blocked before reaching the upstream
- **Encoding-aware filtering**: `decode.rs` decodes Base64 (standard and URL-safe), percent-encoding, double-encoding, and Unicode (NFC + Bidi-control stripping) variants of every argument before applying block patterns — catches obfuscated bypass attempts
- **Schema cache**: `schema_cache.rs` caches per-agent `inputSchema` entries populated from `tools/list` responses; used by the validation middleware
- **Expanded `AuthMiddleware`**: full allowlist/denylist enforcement and API key / JWT validation moved into the middleware pipeline
- **Security test suite**: `attack_scenarios.rs` (SSRF, path traversal, credential leaks, SQL injection, prompt injection variants) and `security_coverage.rs` (payload filter and injection detection coverage)
- **`gateway-test.yml`** fixture for the integration test environment

### Changed
- Integration tests migrated from shell scripts (`test-http.sh`, `test-stdio.sh`) to Rust (`tests/http_gateway.rs`, `tests/stdio_gateway.rs`)
- Stdio tests marked `#[ignore]` — require `npx` at runtime, excluded from CI

---

## [0.6.0] — 2026-03-29

### Added
- **Wildcard tool matching**: glob patterns (`read_*`, `*_file`, `fs/*`) in `allowed_tools` / `denied_tools`
- **`/health` endpoint v2**: reports per-upstream circuit state (`{"status":"ok","upstreams":{"default":true,"filesystem":false}}`)
- **Per-agent upstream timeout**: `timeout_secs` field overrides the global 30s default
- **`default_policy`**: top-level fallback for agents not listed in config (rate limit, denied tools, timeout)
- **`X-Request-Id`** header on every response for end-to-end tracing
- **OAuth 2.1 / multi-provider auth**: list form of `auth:` accepts multiple providers; first valid token wins
- **OpenTelemetry tracing**: `telemetry.otlp_endpoint` exports spans per `tools/call`
- **Prompt injection detection**: `block_prompt_injection: true` in `rules` enables 7 built-in patterns
- **`filter_mode: redact`**: scrubs matching values to `[REDACTED]` and forwards the sanitised request instead of blocking
- **Rate-limit response headers**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, and `Retry-After`
- **`/dashboard`** endpoint — HTML audit log viewer with per-agent filtering

---

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
