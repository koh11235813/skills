# Harness adapter evidence record

Keep the common workflow capability-first. Put runtime-specific tool names, paths, permissions, and lifecycle details in `references/harness-adapters/<harness>.md` only after recording evidence.

## Adapter admission rules

For every added or changed adapter, record:

- a primary public document or a pinned source permalink;
- the version, commit, or observation date;
- which capability is confirmed, unavailable, or only conditional;
- the safe fallback when that capability is absent.

Do not infer behavior from a similarly named tool. A current-session failure blocks that capability even when static documentation says it exists.

## Current evidence

| Adapter | Evidence | Last checked | Important fallback |
|---|---|---|---|
| Claude Code | Official docs (sub-agents, skills, worktrees, workflows, permission-modes, tools-reference), fetched 2026-07-22; current-session observation 2026-09-06 of persistent Agent/SendMessage, Codex MCP threads, and agmsg turn-hook/tmux delivery; current-session observation 2026-09-08 that skills with `disable-model-invocation: true` (upstream `grill-me`, `grill-with-docs`) are absent from the available-skills listing while `grilling`, `domain-modeling`, `tdd` are present; 2026-10-31 Claude Code session observations with pi 1.2.0 and codex-cli 0.166.0-alpha.6: pi model resolution, workspace write and same-ID continuation; codex exec workspace write, thread/resume continuity and OpenRouter profile reply; plugin sol/high read path only (max rejected, profile passthrough unobserved); Haiku/tmux pi write with exit 0, foreground 600s cap, Workflow driver and pi sandbox unverified; see [Implementer CLI](claude-code.md#implementer-cli) | 2026-10-31 | Prefer a confirmed implementer CLI; use native write delegates or inline when none is confirmed. Work sequentially or inline when write isolation, persistent delivery/replies, the codex review chain, or a needed skill is absent. |
| Codex | Official subagent guidance; current-session observation 2026-09-06 of persistent MCP/agmsg implementation, goal tools and TUI replacement, with turn-hook delivery confirmed and goal auto-termination unverified | 2026-09-06 | Do work inline when delegation, read-only review, or writable artifacts are not exposed; use explicit phase continuation when goal support is unconfirmed. |
| OpenCode | Public docs and source commit `c9db6e9`; current-session observation 2026-09-06 that `/goal` is a plain prompt with no continuation | 2026-09-06 | Treat task permissions as controls, not write isolation; use sequential writes without an isolated worktree. |
| Hermes Agent | Source commit `e57918a` and current-session delegation observation; current-session observation 2026-09-06 of `/goal` standing-goal continuation that did not self-terminate (judge error) | 2026-09-06 | Do work inline or sequentially when `delegate_task` is unavailable or its runtime fails. |
| [Pi](pi.md) | [Official docs](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/docs) and [subagent example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent), inspected in installed `@earendil-works/pi-coding-agent` 1.2.0; current-session tool schema and local agent/extension definitions; 2026-10-15 live parallel dispatch of two `planner` children and comparison of local agents with the sample agents | 2026-10-15 | Core skill loading is available; parallel delegation and local guard-backed worktrees are conditional. Read-only enforcement is unverified for the observed agents. Model overrides come from agent frontmatter (every sample agent declares one) and need a reachability check; a write-capable `worker` is the preferred write delegate when registered. No persistent delegate is established. Survey/build inline or sequentially, and require an explicit human exception when external review cannot run. |

Update the relevant adapter and this table together when new evidence changes a capability claim.
