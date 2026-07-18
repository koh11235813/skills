# MEMO — porting this workflow beyond Claude Code

Purpose: a forward-looking sketch of how each Claude-Code-specific
mechanism in `SKILL.md` would map onto a different agent runtime (Codex
CLI running this workflow itself, OpenCode, etc.). This is not a
finished spec — it's a starting point for a future session, to be
validated empirically on the first real cross-runtime attempt, not
trusted as already designed.

## Mapping table (one row per Claude-Code mechanism)

- **Explore subagents (Phase 0)** — parallel codebase survey. Portable
  concept: yes. Needs: any runtime with concurrent subagent/tool
  spawning plus a read-only "explore" persona. Open question: does the
  target runtime support true parallel execution, or only sequential —
  if sequential, does "1-3 explorers" still make sense, or collapse to
  "do it yourself, one pass"?

- **`Skill` tool + available-skills listing (Phase 1 installed-skill
  checks)** — dynamic capability detection. Portable concept: yes.
  Needs: an equivalent "what's installed" introspection surface in the
  other runtime. Open question: some runtimes have no installed-skills
  concept at all — then detection collapses to "just do the interview
  inline," which the fallback chain in `SKILL.md` already covers, so
  this may need no new logic, just confirmation that the fallback is
  reachable without the listing existing at all.

- **`mcp__codex__codex` / `/codex:rescue` (Phase 2 & 4 external
  review)** — already close to runtime-agnostic, since it calls out to
  Codex regardless of who's orchestrating. Special case: if the
  orchestrating runtime IS Codex itself, "call codex" becomes
  self-referential. Needs a rule like "resume in a fresh, contextless
  thread" instead. Flag as unsolved.

- **`Agent(model=...)` per-call tiering + the `Workflow` tool
  (Phase 3)** — the `Workflow` tool specifically (workflow scripts with
  `agent()` calls) is a Claude-Code-only mechanism. Needs: the other
  runtime's task/subagent fan-out primitive, with a per-call model/tier
  override if one exists. Open question: does OpenCode / Codex CLI
  expose per-subtask model selection, or is model fixed per session — if
  fixed, model-tiering degrades to "always use the session default," and
  that should be stated explicitly rather than silently dropped.

- **Weak-model legibility probe (Phase 2)** — the concept ports directly
  (spawn a deliberately cheap/small model in the same family): Haiku for
  Claude, something like a small-tier model for an OpenAI-orchestrated
  run. Open question: some runtimes may only expose one model tier — in
  that case, skip the probe and say why, rather than faking it with the
  same model.

- **`/tdd` skill (Phase 3)** — the Red-Green-Refactor discipline itself
  is runtime-agnostic; only the "is `/tdd` installed" check is
  Claude-Code specific, and the fallback (inline instructions) already
  covers its absence in any runtime.

- **Human commit gate (Phase 4)** — fully portable already; no
  Claude-specific mechanism involved, just "ask before running a
  mutating command."

## Not yet solved (explicitly flagged, not silently assumed)

- No concrete answer for what a "plan document" convention looks like on
  a Codex-CLI-orchestrated run — does it have anything like Claude
  Code's plan-mode file convention, or does this need its own ad hoc
  location?
- No concrete answer for what "parallel subagents" means in a runtime
  without native fan-out — sequential emulation? multiple terminal
  sessions? Needs investigation, not assumption.
- The self-referential "Codex reviewing Codex" loop noted above.

## Closing note

Treat every row above as a hypothesis, not a decision. The first real
attempt to run this workflow under a different runtime should update
this file with what actually worked, not just what seemed plausible
here.
