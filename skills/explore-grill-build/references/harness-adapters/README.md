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
| Claude Code | Official docs (sub-agents, skills, worktrees, workflows, permission-modes, tools-reference) verified by live fetch, plus current-session observation | 2026-07-22 | Work sequentially or inline when write isolation, the codex review chain, or a needed skill is absent. |
| Codex | Official subagent guidance and current-session capability checks | 2026-07-22 | Do work inline when delegation, read-only review, or writable artifacts are not exposed. |
| OpenCode | Public docs and source commit `c9db6e9` | 2026-07-22 | Treat task permissions as controls, not write isolation; use sequential writes without an isolated worktree. |
| Hermes Agent | Source commit `e57918a` and current-session delegation observation | 2026-07-22 | Do work inline or sequentially when `delegate_task` is unavailable or its runtime fails. |

Update the relevant adapter and this table together when new evidence changes a capability claim.
