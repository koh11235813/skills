# External review (shared by Phase 2 and Phase 4)

This file backs two call sites in `SKILL.md`: the Phase 2 plan review and
the Phase 4 diff review. Both need an independent AI agent — outside this
conversation's context — to look at something before it gets acted on.
The only difference between the two call sites is what gets handed over
(a plan document vs. a diff + touched-files list) and one line of
framing. The tool-selection and result-handling logic below is identical
either way.

## Tool preference order

Try these in order. Stop at the first one that actually works — don't
run more than one strong-model reviewer per call site.

### 1. `mcp__codex__codex` (preferred)

This is a real MCP tool. Check for it the way you'd check for any
deferred tool in this environment. If it resolves, call it with:

- `prompt` — the review ask (plan text or diff, plus the framing below).
- `sandbox: "read-only"` — this is a review, not an edit; there's no
  reason to grant write access for either call site.
- `cwd` — the target repo root.
- Optionally, `config: {"model_reasoning_effort": "high"}` to request
  high reasoning effort. Treat this as best-effort: it isn't a
  documented parameter on the tool's own schema, it's inferred from
  general Codex CLI convention, and it may silently do nothing on a
  given install. Pass it anyway — there's no downside — but don't block
  on confirming it worked, and don't be surprised if the review is
  equally useful without it.

### 2. `/codex:rescue --effort high --wait` (fallback)

If the MCP tool isn't connected in this session, fall back to the
`codex:codex-rescue` subagent:

```
Skill(skill="codex:rescue", args="--effort high --wait <prompt>")
```

This path defaults to **write-capable** Codex runs — its own internal
skill docs are explicit that a read-only ask has to say so in the prompt
text itself, or it may make edits nobody asked for. Always include,
verbatim, in the prompt text you pass: "This is a read-only review. Do
not make any edits to any files." There's no flag that enforces this —
the instruction has to live in the natural-language prompt.

Use `--wait` so the review completes before moving on (this is a gate,
not a background task) and `--effort high` explicitly — the plugin
leaves effort unset by default, so it has to be requested.

### 3. Some other agent-spawning mechanism (soft, unconfirmed)

If neither of the above is available, and the environment happens to
have some other way of spawning an external reviewing agent configured
— the user's own workflows sometimes refer to something like this as
`agmsg`, or it might be called something else, or it might not exist at
all here — check for it (e.g. `which agmsg`, or anything locally
documented as an equivalent) and use it if it's genuinely present. Treat
this as a long shot, not an integration: nothing in this skill assumes
such a thing exists, and if the check comes back empty, move on to the
next option without dwelling on it.

### 4. Say so

If none of the above produced a review, don't silently skip this gate
and proceed as though it happened. Tell the user directly that no
independent review could be obtained, and let them decide whether to
proceed without one, retry later, or supply a review some other way.

## Framing the ask

- **Phase 2 (plan review)** — hand over the plan document's full current
  contents. Ask for soundness, feasibility, unstated assumptions, and
  anything the plan is quietly assuming that might not survive contact
  with the real codebase.
- **Phase 4 (diff review)** — hand over the diff (or a way to generate
  it, such as the base commit) and the list of touched files. Ask for
  correctness, missed edge cases, and anywhere the implementation
  drifted from the plan.

In both cases, make the "read-only, no edits" instruction explicit in
the prompt regardless of which tool ended up handling it — cheap to
include, and on the `/codex:rescue` path it's the only thing standing
between "review" and an unplanned write.

## Handling the result

Regardless of which tool answered:

- Present findings ordered by severity, preserving whatever structure
  the tool returned (verdict, findings, open questions, next steps).
- If the tool marked something as an inference or an uncertainty, keep
  that distinction visible — don't flatten it into a flat assertion.
- **Never auto-apply.** Whether the finding is about the plan or the
  diff, it's input to a decision someone makes explicitly — surface it
  and stop. This mirrors `codex-result-handling`'s own rule for
  `codex:codex-rescue` output, and applies here regardless of which tool
  path produced the review.
