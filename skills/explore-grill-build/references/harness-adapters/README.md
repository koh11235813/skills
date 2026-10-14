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
| Claude Code | Official docs (sub-agents, skills, worktrees, workflows, permission-modes, tools-reference), fetched 2026-07-22; current-session observation 2026-09-06 of persistent Agent/SendMessage, Codex MCP threads, and agmsg turn-hook/tmux delivery; current-session observation 2026-09-08 that skills with `disable-model-invocation: true` (upstream `grill-me`, `grill-with-docs`) are absent from the available-skills listing while `grilling`, `domain-modeling`, `tdd` are present | 2026-09-08 | Work sequentially or inline when write isolation, persistent delivery/replies, the codex review chain, or a needed skill is absent. |
| Codex | Official subagent guidance; current-session observation 2026-09-06 of persistent MCP/agmsg implementation, goal tools and TUI replacement, with turn-hook delivery confirmed and goal auto-termination unverified | 2026-09-06 | Do work inline when delegation, read-only review, or writable artifacts are not exposed; use explicit phase continuation when goal support is unconfirmed. |
| OpenCode | Public docs and source commit `c9db6e9`; current-session observation 2026-09-06 that `/goal` is a plain prompt with no continuation | 2026-09-06 | Treat task permissions as controls, not write isolation; use sequential writes without an isolated worktree. |
| Hermes Agent | Source commit `e57918a` and current-session delegation observation; current-session observation 2026-09-06 of `/goal` standing-goal continuation that did not self-terminate (judge error) | 2026-09-06 | Do work inline or sequentially when `delegate_task` is unavailable or its runtime fails. |

Update the relevant adapter and this table together when new evidence changes a capability claim.
