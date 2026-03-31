# GEMINI.md - Arbiter Context

## Project Overview
**Arbiter** (formerly `arbiter`) is a high-performance security proxy designed to sit between AI agents (like Cursor, Claude, etc.) and MCP (Model Context Protocol) servers. It enforces security policies, authentication, rate limiting, and audit logging to ensure that tool calls and data exchange remain secure and controlled.

### Core Technologies
- **Language**: Rust (Edition 2024)
- **Runtime**: `tokio` (Async/Await)
- **Web Framework**: `axum` (for HTTP/SSE transport and dashboard)
- **Database**: `rusqlite` (for local audit logging)
- **Configuration**: YAML with hot-reload support (via `watch` channel and `SIGUSR1`)
- **Observability**: `prometheus` (metrics), `opentelemetry` (tracing), and structured `tracing` logs.

### Key Features
- **Authentication**: Supports JWT/OIDC (Google, GitHub Actions, Auth0, Okta), pre-shared API keys, and Bearer tokens for admin endpoints.
- **Authorization**: Granular per-agent policies with allowlists/denylists for tools (supporting glob wildcards like `read_*`).
- **Rate Limiting**: Sliding window rate limiting per agent, per tool, and per client IP.
- **Data Filtering**: 
    - **Request Redaction**: Scrub sensitive patterns (passwords, keys) from tool arguments.
    - **Response Redaction**: Filter sensitive data from upstream server responses.
    - **Prompt Injection Detection**: Built-in detection for common prompt injection patterns.
- **Reliability**: Circuit breaker for upstreams, configurable per-agent timeouts, and health checks.
- **Audit Logging**: Fan-out logging to multiple backends simultaneously (SQLite, Webhook, Stdout).
- **Dashboard**: Built-in audit viewer at `/dashboard` with agent-based filtering.

## Architecture
The project is structured into several modular components:
- `McpGateway`: The central engine coordinating policy checks and upstream forwarding.
- `Pipeline`: A composable middleware system (`AuthMiddleware`, `RateLimitMiddleware`, `PayloadFilterMiddleware`).
- `Transport`: Pluggable transport layers (`HttpTransport` for SSE/HTTP and `StdioTransport` for local pipes).
- `Upstream`: Handles communication with backend MCP servers (`HttpUpstream` with circuit breaker support).
- `AuditLog`: Abstracted logging interface with multiple implementations.

## Building and Running
### Build
```bash
cargo build --release
```

### Running the Gateway
The gateway requires a configuration file (defaulting to `gateway.yml`).
```bash
./target/release/arbiter [config.yml]
```

### Running Tests
- **Unit Tests**: `cargo test`
- **Integration Tests**:
    - HTTP: `bash test-http.sh`
    - Stdio: `bash test-stdio.sh` (requires Node.js)

### Common Commands
- **Reload Config**: `kill -USR1 $(pidof arbiter)`
- **Query Audit Log**: `cargo run --bin arbiter-audit -- [db_path] [flags]`
- **Health Check**: `curl http://localhost:4000/health`
- **Metrics**: `curl http://localhost:4000/metrics`

## Development Conventions
- **Trait-Based Design**: Transports, Audit Logs, and Upstreams are all trait-based to allow easy extension.
- **Hot-Reload**: Always use `watch::Receiver<Arc<LiveConfig>>` for components that need to react to configuration changes.
- **Error Handling**: Use `anyhow` for high-level errors and `thiserror` if specific error variants are needed in the future.
- **Logging**: Use the `tracing` macros (`info!`, `warn!`, `error!`, `instrument`). Prefer structured logging where possible.
- **Testing**: Every new feature should include unit tests. Integration tests are preferred for transport-level changes.
- **Formatting**: Adhere to standard `cargo fmt` and `cargo clippy` suggestions.
