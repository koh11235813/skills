# Manager loop

Use this Phase 3 execution mode for a long plan with several independently verifiable phases, when `delegate_persistent` is confirmed: a delegate can receive another message with its prior context intact, and the orchestrator can wait for and inspect its reply. Treat unverified persistence as unavailable. Skip the manager loop for a small plan that fits one sitting; use the ordinary slice loop in [../SKILL.md](../SKILL.md).

A single agent can spend longer and longer polishing one detail while overall progress asymptotes. The manager loop makes progress explicit: one persistent implementer completes one phase at a time, then the manager verifies the result before handing over the next phase.

## Prepare the handoff

The **manager** is the orchestrating agent. It owns phase boundaries, verification, correction messages, and the decision to advance. The **implementer** is the persistent delegate. It owns implementation and the progress page. Use the confirmed runtime mapping in `harness-adapters/` to message the same implementer again and inspect its reply.

Cut the reviewed plan's checklist into ordered phases, each with a concrete output and its own verification. Preserve dependencies and give each item a stable ID. Make the first item of the first phase build the progress page specified below, including the complete checklist for all phases. Share the plan and workspace location before dispatch; the plan remains the source of truth.

For a peer without turn/monitor delivery, include in its first message a duty to start a background inbox poll at an agreed interval, keep inspecting its live output, and implement received phases; see `harness-adapters/` for the boot-prompt mapping and the nudge option when lower latency is needed.

Run one phase at a time. While the loop is running, the manager does not edit code: the implementer owns writes in the shared working tree. The manager reads the diff, runs checks, and sends instructions. Additional write-capable delegates still require the isolation and parent-controlled integration gate in SKILL.md; disjoint filenames alone do not establish isolation.

## Send one phase

Fill in this template for each phase. Paste its checklist items verbatim from the plan, including their verification criteria; select N explicitly (default 20 minutes).

```text
Implement phase <phase ID> completely and extremely well, not perfectly.
Read the full plan at <plan path> first. Work in <workspace>.
You own this phase's implementation; I am the manager and will verify it.

Checklist for this phase (verbatim from the plan):
<items and their verification criteria>

For each behavior, follow Red → Green → Refactor: one failing test, the
minimal implementation, then refactor. Rerun the full test suite after
each item. Use vertical slices, not a batch of tests followed by a batch
of implementation. For documentation-only items in a repo without tests,
verify the specified content, links, and diff; report that no suite exists.

After each verified item, append its timestamp, phase, and item ID to
<plan dir>/progress/status.tsv and regenerate <plan dir>/progress/index.html.
Check a box only after its verification passes.

Stall limit: <N> minutes without checking a box. If that limit is reached,
record the current item and blocker under unresolved, leave its box
unchecked, and move to the next item whose dependencies are satisfied.
The <N>-minute window restarts when you start a new item and when you
receive a correction message.
Record blocked dependents as unresolved too. Do not return until this
phase is done or stalled. Stay within this phase; do not commit.

Reply with all four fields:
done: <completed item IDs>
unresolved: <required; [] if empty, otherwise item IDs, blockers, and caveats>
verification: <checks actually run and their results; identify unavailable checks>
diff_summary: <files touched and what changed>
```

## Verify, then advance

On each reply, the manager reads the actual diff, runs the relevant tests or documented checks itself, and compares the result and checked boxes against the phase's plan items. A completion claim or a green counter is not verification. Account for every item in `done` or `unresolved`, and inspect the evidence before accepting the phase.

If verification fails or the reply is incomplete, send a correction or "continue" message to the same implementer for the same phase. Include the failed checks and the remaining items; advance only after those are resolved or explicitly recorded as deferred in the plan with their dependency impact assessed. An unresolved item stays unchecked. If it blocks later phases, resolve the blocker before dispatching those phases. Bring decisions requiring human input back to the human rather than silently reducing the plan's scope.

The manager also watches the progress page's last-check timestamp or uses an inbox timeout to notice silence. Measure N from the later of the last check and the last dispatched message; after N minutes without a check, request the current item's blocker and a structured status reply. A stale page is a reason to inspect the implementer's state, not proof that it has stopped; avoid launching a second writer while the first may still be running. Resume useful work through the same implementer and record stalled items under `unresolved`.

The manager cannot put a Claude Code subagent into `/goal` mode: that is a user-side command that installs a Stop hook, and whether a literal `/goal ...` string sent over agmsg to a claude-code peer is interpreted as a slash command is unverified. A Codex implementer has its own goal mechanism: the TUI `/goal` command and goal tools, with continuation fragments injected between turns. Consult `harness-adapters/` for the confirmed runtime mapping and its limits; availability in a TUI does not establish availability over MCP. The portable continuation contract remains "do not return until done or stalled", followed by a manager "continue" message when a reply is incomplete.

This verification is the orchestrator's own check, not an external review per phase. External findings are never auto-applied; surface them for an explicit decision under SKILL.md's existing rule. After the last phase is verified and any unresolved work is explicitly accounted for, run Phase 4 unchanged: self-review, one external diff review over the complete diff, then the explicit human commit gate. The manager loop does not authorize a commit or replace that gate.

## Checklist page contract

Build `<plan dir>/progress/index.html` next to the plan, with `<plan dir>/progress/status.tsv` as its check history. Each verified check appends one tab-separated line containing an ISO-8601 timestamp, phase, and item ID. When the manager rejects a checked item, append another line for the same item with a fourth field `revoked`; the latest line for an item decides its state, so a rejected completion does not reappear on regeneration. Regenerate the HTML from that history after every check or revocation, using a tiny inline standard-library script or a manual rewrite; no shipped script is required.

The page is a single self-contained HTML file that opens over `file://` with no external assets. Include the complete checklist grouped by phase, a checkbox state for each item, a "checked / total" counter, the timestamp of the last check, and an inline SVG line chart of checked count over time. Before the first check, show zero completed and that no check has occurred yet. Keep unfinished or unresolved items visible and unchecked.

Check an item only after its specified verification — a test, diff read, or file-existence check — has been performed successfully. Verify the initial page, then check the first item and regenerate it immediately. The page records verified progress; editing a checkbox in the browser alone is not evidence of completion.
