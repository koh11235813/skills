---
name: explore-grill-build
description: End-to-end workflow for implementing a nontrivial feature or fix, from first look to committed code. Fans out parallel Explore subagents to survey the codebase, runs a grilling-style interview (auto-selecting /grill-me or /grill-with-docs based on whether the repo already has domain docs) to turn vague requirements into a written plan, gets that plan independently reviewed by both a strong external agent and a deliberately weak model used as a legibility probe, implements it test-first via /tdd with model-tiered subagents, and runs a three-stage review gate (self-review, external review, explicit human go-ahead) before anything is committed. Use this whenever the user asks to build, implement, add, or fix a nontrivial feature; says "let's build this," "implement X," "build this properly," or wants a rigorous, verified, reviewed process instead of diving straight into code; or before starting any substantial coding work in a repo where correctness and review actually matter. Skip it for one-line fixes, trivial config edits, or when the user explicitly wants something quick and dirty.
---

# Explore, Grill, Build

Implement a nontrivial change the way you'd want it done if you weren't in
a hurry: understand the codebase before proposing anything, interview
until the plan is actually solid, get that plan checked by minds outside
this conversation before committing to it in code, build it test-first,
and never let code reach a commit without an explicit human yes.

Five phases, each producing something the next one consumes. Don't skip a
phase's output — Phase 2 reviews the plan Phase 1 wrote down, Phase 3
implements the plan Phase 2 signed off on, Phase 4 reviews the diff
Phase 3 produced.

## Scope

This is a five-phase gauntlet. It's worth it for a feature with real
design space — where "what should this actually do" isn't already
obvious, where getting it wrong is expensive to unwind, or where the user
is explicitly asking for rigor. It's waste for a one-line fix, a config
tweak, a typo, or anything where the entire implementation is unambiguous
once you've read the request. If, partway through, a task that looked
substantial turns out to be small, say so and collapse the remaining
phases instead of performing ceremony for its own sake — the discipline
exists to serve the outcome, not the other way around.

## The five phases

| Phase | Does | Produces |
|---|---|---|
| 0 — Explore | Parallel `Explore` subagents survey the relevant codebase | A synthesized brief |
| 1 — Grill | Auto-selected interview turns the brief + user intent into a concrete plan | A written plan document |
| 2 — External plan review | A strong external agent and a deliberately weak model both review the plan | Plan updated in place, go/no-go to build |
| 3 — TDD build | Red → Green → Refactor via tracer-bullet slices, model-tiered subagents | Working, tested implementation |
| 4 — Review gate | Self-review → external diff review → explicit human go-ahead | Commit, or not |

## Phase 0 — Explore

Before interviewing anyone about anything, look at the codebase yourself
— or rather, have subagents do it in parallel so you're not burning your
own context on a linear crawl.

Spawn `Agent` calls with `subagent_type=Explore` — the same agent type
Claude Code's own Plan Mode uses for its "Phase 1: Initial Understanding"
step — to survey the parts of the codebase relevant to the task: existing
patterns for similar features, the files that will likely need to
change, related tests, and any prior art (similar modules, similar past
PRs).

Scale the number of parallel explorers to how uncertain the scope is, not
by habit:

- **1 explorer** — the task already names the specific file(s) or module,
  or it's a narrow, well-bounded change.
- **2–3 explorers** — the task is broad, spans multiple subsystems, or
  you genuinely don't know yet where the relevant code lives. Split them
  by area of concern (e.g. one on the data layer, one on the API
  surface, one on existing similar features) rather than having all
  three redo the same crawl.

Don't exceed 3 — beyond that you're paying for parallel context you
won't be able to synthesize usefully.

Once the explorers return, synthesize their findings into a short brief:
what exists, what pattern to follow, what's surprising. Carry this brief
into Phase 1 as-is — the interview should build on what you just
learned, not re-discover it from zero. `/grill-me` and `/grill-with-docs`
will still explore further themselves as specific questions demand it
during the interview (that's expected and fine — this phase gives them a
head start on the broad picture, not a replacement for depth on a
specific branch).

## Phase 1 — Grill

Use the Phase 0 brief plus a grilling-style interview to turn "what the
user said they want" into a concrete, resolved implementation plan.

### Choosing which grilling skill to run

Two skills do this: `/grill-me` (pure interview, no file output) and
`/grill-with-docs` (the same interview, plus challenging terminology
against the repo's existing domain model and updating
`CONTEXT.md`/`docs/adr/` inline). Pick based on the target repo's actual
documentation state — don't ask the user which one to use, and don't
guess from vibes.

1. **Structural check.** Does `CONTEXT.md` exist at the repo root? Does
   `CONTEXT-MAP.md` exist at the root (multi-context repo)? Does
   `docs/adr/` exist and contain at least one `.md` file? If any of these
   are true, the repo already has — or has already started — the
   documentation structure `/grill-with-docs` maintains. Use it.

2. **If the structural check is empty, ask — once, with a
   recommendation.** Don't guess whether this repo "should" have that
   documentation structure; that judgment is easy to get wrong in both
   directions (imposing docs on a repo that's deliberately kept lean, or
   skipping them on a repo that would clearly benefit). Ask directly:
   "This repo doesn't have CONTEXT.md/ADRs yet — want me to start that
   structure as part of this session, or keep this to a plain interview?
   I'd lean toward [X] because [reason]." Then proceed with whichever the
   user picks.

3. **Confirm it's actually installed, then invoke it.** Check the
   available-skills listing surfaced in context at session start — the
   block naming every installed skill and its description — for an
   entry named `grill-me` or `grill-with-docs`. If the chosen name is
   there, call it:

   ```
   Skill(skill="grill-with-docs", args="<the Phase 0 brief and what's being built>")
   ```

   If the name you want isn't in that listing, it isn't installed here —
   don't call it anyway. Fall through to the next option.

### Fallback chain if neither is installed

If neither `grill-me` nor `grill-with-docs` appears in the
available-skills listing, check — with low expectations — for a skill or
command literally named `grilling`. It's an older name from a different
skills collection (`mattpocock/skills`) and may or may not exist in
whatever environment is running this workflow; this is a soft,
low-emphasis fallback line, not a documented feature of this skill. If
it's there, use it the same way. If it's not, don't dwell on it.

If nothing in that chain is available, conduct the interview yourself,
directly: ask one question at a time, each with 2-4 concrete options
plus an implicit "or something else," and always state your own
recommended answer before waiting on the user's. This preserves the
discipline that makes grilling effective — one question at a time, a
recommendation offered every time — even without the packaged skill
doing it for you.

### Writing the plan down

The interview only has value if its conclusions survive past the
conversation. As branches resolve, keep a running plan document up to
date — don't wait until the interview feels "done" to write it, and
don't rely on chat history as the record. Phase 2's reviewers and
Phase 3's implementers each need a single file to read, not a transcript
to reconstruct.

- If this session already has an active Claude Code plan-mode file
  (you'll know because you were handed a specific plan-file path to
  write to at the start of the session), use that file directly.
- Otherwise, default to the same convention: create the plan at
  `~/.claude/plans/<slug>.md`, where `<slug>` is a short kebab-case name
  for the feature (e.g. `stripe-webhook-retry`). Tell the user the path
  once you've created it.
- If the user directly specifies a different location for this run (for
  example, a repo-local `docs/` path so the plan travels with the code
  in git), use that instead — their explicit instruction overrides the
  default.

Write enough into it that an independent reviewer — human or AI, with no
access to this conversation — could evaluate it cold: the problem being
solved, the chosen approach and why (including alternatives that came up
during grilling and why they were rejected), the concrete
interface/behavior changes, and any open risks or assumptions still on
the table. Update it inline as decisions resolve, the same discipline
`/grill-with-docs` uses for `CONTEXT.md` — capture as you go, don't
batch.

## Phase 2 — External plan review

Once the plan document feels solid — the interview has resolved its
major branches and you'd be comfortable explaining the approach to
someone cold — get it checked by reviewers outside this conversation,
before writing any code. The point of "outside" is specific: an agent
that didn't participate in the interview doesn't share whatever
assumptions or momentum built up while you and the user converged. Sunk
cost and confirmation bias are conversational phenomena; a reviewer with
no conversation to be biased by is immune to them by construction.

Run two independent checks, both reading the plan document itself, not
the conversation.

### Strong-model review

See [references/external-review.md](references/external-review.md) for
the tool-preference chain. Frame the ask as: review this implementation
plan for soundness, feasibility, unstated assumptions, and anything it's
quietly assuming that might not hold once it meets the real codebase.
This is a review, not a build — make that explicit regardless of which
tool ends up handling it.

### Weak-model legibility probe

Separately — in addition to, not instead of, the strong-model review —
spawn a deliberately smaller/cheaper model in the same family as
whatever is orchestrating this workflow. If Claude is running this
workflow, that's an `Agent` call with `model: "haiku"`. If some other
agent family is running this same workflow, the equivalent is whatever
that family's small/cheap tier is — the instruction is "spawn a
deliberately smaller model in your own family," not "spawn Haiku
specifically." Hand it only the plan document, with instructions to
explain the plan back in its own words and flag anything it's unsure
about or would need clarified before it could start implementing.

The point isn't the weak model's opinion on plan quality — its technical
judgment isn't worth much, and that's fine, that's not what it's for.
The point is what it *fails to understand*. A strong model can silently
paper over an underspecified plan by inferring the missing pieces from
general knowledge; a weak model can't do that as well, so its confusion
is a direct signal of exactly where the plan document itself is
underspecified. Treat every point of confusion it surfaces as a defect
in the plan document, not a defect in the weak model's comprehension —
the fix is to go rewrite that section of the plan with more explicit
detail, not to explain it better to the weak model in that one throwaway
session. If the weak model "gets it" cleanly, that's a mildly reassuring
signal about the plan's clarity, but absence of confusion is much weaker
evidence than presence of confusion — don't over-read a clean pass as
proof the plan is good.

This probe is specific to reviewing plans, not diffs — it isn't repeated
in Phase 4. A diff is either correct or it isn't; a cheap model's read
on that isn't diagnostic the same way an underspecified plan is.

Fold findings from both reviews back into the plan document (same
update-inline discipline as Phase 1) before moving on. If either review
surfaces a fundamental problem, that's a reason to go back into the
interview, not to patch around it during implementation later.

### Before moving to Phase 3

Show the user the plan document plus a short summary of what both
reviews found, and confirm you're clear to start building. This doesn't
need to be as heavy as the Phase 4 commit gate — it's a "does this still
look right to you" checkpoint, not a re-litigation of the whole
interview — but don't silently roll from review straight into
implementation without it. The entire point of grilling and reviewing
was to arrive at a plan the human is actually bought into, and that only
holds if they've seen the final version, reviews included.

## Phase 3 — TDD implementation

Implement the reviewed plan test-first.

### Which loop

Check the available-skills listing for `tdd`. If present, invoke it —
`Skill(skill="tdd", args="<the plan, or the slice of it being implemented now>")`
— and follow its actual loop: **Red → Green → Refactor**, via
vertical-slice tracer bullets (one test, one implementation, repeat —
never all tests first, then all implementation). After the last Refactor
step for a given slice, rerun the full test suite once more as an
explicit final check. `/tdd` doesn't name this as a fourth phase and
neither should you — treat it as the tail end of Refactor, not a
separate ritual.

If `tdd` isn't installed in this environment, run the same discipline
inline: for each behavior in the plan, write one failing test, write the
minimal code to pass it, and once a slice's tests are all green,
refactor — extract duplication, deepen modules, apply SOLID where it's
natural — then rerun the whole suite. Writing a batch of tests before
any implementation is horizontal slicing; it produces tests that check
imagined shape instead of real behavior, and this workflow explicitly
rejects it regardless of which path implements the discipline.

### Fanning out the slices

If the plan breaks into several largely-independent tracer-bullet
slices, there are two ways to parallelize, depending on what's
available:

**With the `Workflow` tool** (worthwhile once there are enough
independent slices to justify the orchestration overhead): write a
workflow script that calls `agent()` once per slice, choosing `model`
per call based on how hard that specific slice actually is — not
uniformly across every call.

**Without it** (implementing directly, or spawning a handful of parallel
`Agent` calls): same idea, fewer moving parts. If the slices are *fully*
independent — no shared interface or state still being designed
concurrently — spawn them as parallel `Agent` calls, again choosing
`model` per call by difficulty. If they're not independent (a later
slice needs an interface an earlier one is still defining), don't
parallelize them: implement in dependency order instead, either yourself
or one subagent at a time.

A starting point for the difficulty → model mapping — adjust this
freely, it's a default suggestion, not a fixed rule:

| Slice difficulty | Example | Suggested model |
|---|---|---|
| Mechanical / boilerplate | codegen from a schema, repetitive CRUD wiring, renames, config plumbing | cheapest/fastest available (e.g. `haiku`) |
| Standard feature work | typical business logic, most tracer-bullet tests | inherit the session default — don't override |
| Architecturally tricky | concurrency, novel abstractions, security-sensitive code, ambiguous interface design, cross-cutting refactors | the strongest available model (e.g. `opus`) |

### The one invariant

Whichever path you used — `Workflow`, parallel `Agent` calls, or direct
implementation — you, the orchestrating agent, re-check each slice's
output yourself before moving on to the next one or calling the phase
done. Delegating a slice to a subagent, at any tier, delegates the
typing, not the responsibility for whether it's right. Read the diff,
run the tests, confirm it actually matches that slice of the plan.

## Phase 4 — Post-implementation review chain

Before anything gets committed, run three gates, in this order, every
time. Each catches a different failure mode; none substitutes for the
others.

### 1. Self-review

Read your own (or your subagents') diff directly. Run tests and
typecheck. If the `code-review` skill is available, invoke it against
the working diff — this is the diff-based reviewer. It's a different
tool from `code-review:code-review`, which reviews an already-open
GitHub PR via `gh` and doesn't apply here, since nothing has been pushed
yet.

Unlike the external review below, applying fixes directly here is fine
— `/code-review --fix` is a reasonable choice for this specific
sub-step, since it's the orchestrator checking its own work, and the
Phase 4.3 human gate still sits between this and any actual commit.

### 2. External agent review

Same tool-preference chain as Phase 2 — see
[references/external-review.md](references/external-review.md) — but
now hand it the actual diff and the touched-files list instead of the
plan document. Frame the ask as reviewing real code: correctness, edge
cases the tests might have missed, anywhere the implementation drifted
from the reviewed plan.

Per that reference's ground rule: never auto-apply anything this review
suggests. Surface the findings; let the human or an explicit next step
decide what happens to them. This rule is absolute here, unlike the
self-review step above — this is an outside opinion, not the
orchestrator's own already-checked work.

There's no weak-model legibility pass here — that technique specifically
catches underspecified *plans*, where a cheap model's confusion is
diagnostic of missing detail. A diff is either correct or it isn't; a
cheap model's read on that isn't informative the same way.

### 3. Human gate

Summarize, in one place, what was built and what both review passes
(self and external) found — including anything you deliberately decided
not to act on, and why. Then explicitly ask the human whether it's OK to
commit.

Never commit without that explicit go-ahead. This isn't specific to this
workflow — it's standing behavior in this environment already — but
it's worth restating here precisely because it's the last step, and the
last step is exactly where a long, successful run tempts an agent to
just wrap up on its own momentum instead of actually asking.

## Cross-cutting invariants

A few things hold across every phase above, worth stating once instead
of five times:

- **External findings are never auto-applied** (except the explicit
  Phase 4.1 self-review carve-out). Whether it's the Phase 2 plan review
  or the Phase 4 external diff review, an outside agent's output is
  input to a decision someone makes explicitly — never a patch applied
  silently.
- **The plan document is the source of truth, not the conversation.**
  Every phase after Phase 1 reads the plan, not chat history. Keep it
  current.
- **Delegation doesn't remove verification.** Whatever tier of subagent
  did the work, the orchestrator checks it before moving on.
- **Scale effort to the task.** See Scope, above — this doesn't stop
  mattering once you're mid-flow.

For notes on how each Claude-Code-specific mechanism here (`Explore`
subagents, the `Skill` tool, the `Workflow` tool, per-call `model`
tiering) would map onto a different agent runtime, see `MEMO.md` in this
skill's directory. That file is a forward-looking sketch, not a finished
spec.
