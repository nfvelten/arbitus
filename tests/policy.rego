package mcp
import future.keywords.if
default allow := true
allow := false if input.agent_id == "untrusted-agent"
