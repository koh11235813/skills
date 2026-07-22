# Codex adapter

Use this adapter only after inspecting the current session's visible tools, permissions, sandbox, and writable roots. Codex may delegate when the user or applicable project or skill instructions request it, but the current tool menu and policy determine what can actually run. [Subagent guidance](https://learn.chatgpt.com/docs/agent-configuration/subagents#triggering-subagent-workflows)

## Capability mapping

- Delegate independent survey or review work only when the session exposes a subagent mechanism. State the division of work, whether to wait, and the required result in each prompt.
- Use parallel delegates only for read-only, independent exploration. The orchestrator must synthesize and verify their results.
- Treat a delegate as an external reviewer only when a fresh context and an enforced read-only sandbox are both confirmed. Invoke tools with only fields present in the current schema.
- Use the common `/tmp` plan artifact first. Mirror it only when Codex exposes a writable, persistent plan path; do not assume a Claude-compatible plan location exists.
- Inspect current approval and sandbox constraints before delegating writes. Without confirmed isolated write environments, implement slices sequentially.
