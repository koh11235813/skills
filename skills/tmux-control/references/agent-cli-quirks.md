# Agent CLI quirks

Behavior of specific agent CLIs when driven through tmux. Every entry below is something that was actually observed, with the file that records the observation and the date. Do not add an entry for a CLI you have not driven yourself, and do not generalize one CLI's behavior to another: these TUIs differ in exactly the places that break automation. When an entry turns out to be wrong in the current session, the current session wins.

The sources are the per-harness files under `../../explore-grill-build/references/harness-adapters/`. Cite those, not the directory's `README.md`, which is a summary table rather than the primary record.

## Applies to every CLI here

Send the text and the `Enter` as two separate `send-keys` calls, and confirm submission with `capture-pane`. See the "Send input" section of [../SKILL.md](../SKILL.md) for the two reasons.

## Codex TUI

Source: [`codex.md`](../../explore-grill-build/references/harness-adapters/codex.md), observed 2026-09-06.

- `/goal <objective>` sets a standing goal. Send the `/goal ...` line and the `Enter` as separate calls.
- With a goal already active, a `Replace goal?` dialog appears and needs one further `Enter` before `Goal active` is shown.
- A new objective **replaces** the existing goal rather than adding one. Do not overwrite a goal the user set without their say-so; read the pane first.
- Goal tools are registered in app-server sessions with persistent thread state, which includes the TUI. An MCP thread alone does not give you the goal mechanism.
- agmsg delivery to the observed peer was `turn` mode via a Stop hook in `.codex/hooks.json`, so any keystroke that ends a turn also pulls the inbox.

## Hermes TUI

Source: [`hermes-agent.md`](../../explore-grill-build/references/harness-adapters/hermes-agent.md), observed 2026-09-06 (`gemini-3.8-flash`).

- `/goal <objective>` sets a standing goal that Hermes continues between turns, with a `goal <n>/20` status bar and an injected continuation fragment.
- **It did not stop on its own.** The completion judge failed (`judge error: NotFoundError`) and the loop kept re-running toward the 20-iteration cap.
- `C-c` sent to end that loop ended the **entire Hermes session**, not just the goal. No goal-cancel that keeps the session alive was identified.
- Practical consequence: phrase the objective so its last step is an explicit reply, watch for that reply, and expect to end the loop by hand. Replacement behavior for an existing goal was not observed.

## OpenCode TUI

Source: [`opencode.md`](../../explore-grill-build/references/harness-adapters/opencode.md), observed 2026-09-06 (`Muse Spark 1.3 Free`).

- There is no `/goal` command. A `/goal <objective>` line is taken as an ordinary prompt: the objective ran once and the session stopped, with no goal indicator and no continuation.
- Drive it with an explicit "do not return until done or stalled" phase prompt plus a follow-up message per incomplete reply.

## Claude Code

Source: [`codex.md`](../../explore-grill-build/references/harness-adapters/codex.md), observed 2026-09-06.

- A Claude Code peer with its `Monitor` running on the agmsg watcher receives messages without a tmux nudge. Nudging is for peers whose delivery depends on a turn boundary.
- Whether a literal `/goal ...` string sent over agmsg to a Claude Code peer is interpreted as a slash command is **unverified**. Do not rely on it.
