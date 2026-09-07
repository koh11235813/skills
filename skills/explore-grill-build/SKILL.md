---
name: explore-grill-build
description: End-to-end workflow for implementing a nontrivial feature or fix, from first look to committed code. Surveys the codebase with capability-gated read-only delegates, turns vague requirements into a written plan through a grilling-style interview, reviews that plan independently when an enforced read-only reviewer is available, implements it test-first in verified slices, and runs self-review plus an explicit human commit gate. Use this whenever the user asks to build, implement, add, or fix a nontrivial feature; says "let's build this," "implement X," "build this properly," or wants a rigorous, verified, reviewed process instead of diving straight into code; or before starting any substantial coding work in a repo where correctness and review actually matter. Skip it for one-line fixes, trivial config edits, or when the user explicitly wants something quick and dirty.
---

# Explore, Grill, Build

Implement a nontrivial change the way you'd want it done if you weren't in a hurry: understand the codebase before proposing anything, interview until the plan is actually solid, get that plan checked by minds outside this conversation before committing to it in code, build it test-first, and never let code reach a commit without an explicit human yes.

Five phases, each producing something the next one consumes. Don't skip a phase's output — Phase 2 reviews the plan Phase 1 wrote down, Phase 3 implements the plan Phase 2 signed off on, Phase 4 reviews the diff Phase 3 produced.

## Scope

This is a five-phase gauntlet. It's worth it for a feature with real design space — where "what should this actually do" isn't already obvious, where getting it wrong is expensive to unwind, or where the user is explicitly asking for rigor. It's waste for a one-line fix, a config tweak, a typo, or anything where the entire implementation is unambiguous once you've read the request. If, partway through, a task that looked substantial turns out to be small, say so and collapse the remaining phases instead of performing ceremony for its own sake — the discipline exists to serve the outcome, not the other way around.

## The five phases

| Phase | Does | Produces |
|---|---|---|
| 0 — Explore | Capability-gated discovery delegates survey the relevant codebase | A synthesized brief |
| 1 — Grill | Auto-selected interview turns the brief + user intent into a concrete plan | A written plan document |
| 2 — External plan review | An eligible strong reviewer, plus a weak-model probe when selectable, review the plan | Plan updated in place, go/no-go to build |
| 3 — TDD build | Red → Green → Refactor via tracer-bullet slices, with capability-gated slice fan-out or a manager loop | Working, tested implementation |
| 4 — Review gate | Self-review → external diff review → explicit human go-ahead | Commit, or not |

## Runtime capability check

Before Phase 0, inspect the current runtime's visible tools, permissions, and workspace topology. Mark each capability **confirmed**, **unavailable**, or **unverified**. Never infer support from a harness name, model family, or a similarly named command.

- `plan_artifact` — a writable plan artifact that later reviewers can read.
- `delegate_readonly` — an independent delegate with enforced read-only tools.
- `delegate_parallel` — concurrent delegate dispatch plus a reliable join/result.
- `delegate_model_select` — a genuinely lower model tier for a delegate.
- `delegate_write_isolated` — isolated worktrees, branches, or sandboxes with a parent-controlled integration path.
- `delegate_persistent` — a delegate that can be re-messaged with its prior context intact, whose reply the orchestrator can wait for and inspect.
- `skill_discovery` and `skill_invoke` — discover and invoke an installed skill.
- `diff_access` and `test_runner` — inspect changes and run relevant checks.
- `human_confirmation` — obtain an explicit human decision before committing.

Treat an unverified capability as unavailable. Runtime-specific mappings belong in `references/harness-adapters/`, not in this common workflow.

## Phase 0 — Explore

Before interviewing anyone about anything, survey the codebase. Use one to three independent, read-only discovery delegates only when both `delegate_readonly` and `delegate_parallel` are confirmed. If only the former is confirmed, run delegates sequentially. If neither is confirmed, perform one focused survey yourself. Never claim a fan-out happened when it did not.

Ask each survey to identify existing patterns for similar features, likely files to change, related tests, and prior art such as similar modules or past PRs.

Scale the number of parallel explorers to how uncertain the scope is, not by habit:

- **1 explorer** — the task already names the specific file(s) or module, or it's a narrow, well-bounded change.
- **2–3 explorers** — the task is broad, spans multiple subsystems, or you genuinely don't know yet where the relevant code lives. Split them by area of concern (e.g. one on the data layer, one on the API surface, one on existing similar features) rather than having all three redo the same crawl.

Don't exceed 3 — beyond that you're paying for parallel context you won't be able to synthesize usefully.

Once the explorers return, synthesize their findings into a short brief: what exists, what pattern to follow, what's surprising. Carry this brief into Phase 1 as-is — the interview should build on what you just learned, not re-discover it from zero. `grilling` (and `domain-modeling`, when it runs) will still explore further as specific questions demand it during the interview (that's expected and fine — this phase gives them a head start on the broad picture, not a replacement for depth on a specific branch).

## Phase 1 — Grill

Use the Phase 0 brief plus a grilling-style interview to turn "what the user said they want" into a concrete, resolved implementation plan.

### Companion skills

This phase is designed around two optional companion skills, and Phase 3 around a third. All three are separately installed; `mattpocock/skills` is the recommended source, and the one-line install is in [references/companion-skills.md](references/companion-skills.md).

- `grilling` — the interview itself. Always the first choice when it is present.
- `domain-modeling` — run alongside `grilling` only when the domain-docs decision below says so. It challenges terminology against the repo's existing domain model and updates `CONTEXT.md`/`docs/adr/` inline.
- `tdd` — Phase 3's loop reference (see there).

Resolve availability for each skill independently, and only through the runtime's confirmed skill mechanism (`skill_discovery` plus `skill_invoke`; the concrete calls live in the harness adapters, not here). Distinguish three states: **present** — use it; **missing** — the one-time suggestion below, then the inline fallback; **present but not invocable, or discovery unverified** — the inline fallback, with no install suggestion, because installing more skills won't change that. Never rely on wrapper skills such as `grill-me` or `grill-with-docs`: upstream they are one-line shims around `grilling` and `domain-modeling` and are flagged so that the model cannot invoke them, so they never appear in a model-visible listing even when installed.

**One-time install suggestion.** The first time any of the three is found missing in a session, tell the user once — in one or two sentences — that this workflow has optional companion skills and give the exact command from the reference above. Do not run it yourself, do not wait for it, and do not repeat the suggestion in later phases; carry on with the inline fallback. If a skill under a different name covers the same job (for example a harness-native TDD skill), that counts as present — don't suggest an install just because the literal name is absent.

### Deciding whether domain modeling runs

Pick based on the target repo's actual documentation state — don't ask the user which mode to use up front, and don't guess from vibes.

1. **Structural check.** Does `CONTEXT.md` exist at the repo root? Does `CONTEXT-MAP.md` exist at the root (multi-context repo)? Does `docs/adr/` exist and contain at least one `.md` file? If any of these are true, the repo already has — or has already started — the documentation structure `domain-modeling` maintains. Run it alongside the interview.

2. **If the structural check is empty, ask — once, with a recommendation.** Don't guess whether this repo "should" have that documentation structure; that judgment is easy to get wrong in both directions (imposing docs on a repo that's deliberately kept lean, or skipping them on a repo that would clearly benefit). Ask directly: "This repo doesn't have CONTEXT.md/ADRs yet — want me to start that structure as part of this session, or keep this to a plain interview? I'd lean toward [X] because [reason]." Then proceed with whichever the user picks.

3. **Load what you selected.** `grilling` alone, or `grilling` and `domain-modeling` together, each through the runtime's confirmed mechanism. Whatever the companions instruct, this workflow's capability gates still apply while they run: `grilling` will want to delegate fact-finding to a subagent whenever a question turns on something in the environment — do that only through a confirmed, eligible delegate, and otherwise go look yourself. The underlying rule is the one to keep: a factual question gets researched, not handed to the user.

### Inline fallbacks

**Interview without `grilling`.** Work the design as a tree of decisions in rounds. Each round asks every question whose prerequisites are already settled — the ones you can ask now without guessing at answers you haven't heard — numbered, each with 2-4 concrete options plus an implicit "or something else," and each with your own recommended answer stated up front. Never put a question in the same round as the unresolved decision it depends on; that produces speculative answers and rework. Wait for the user's answers, recompute the frontier, ask the next round. If the runtime or the user limits how many questions fit at once, split a round rather than drop the recommendations. Stop when you can state the plan back and the user agrees it's what they meant.

**Domain modeling without `domain-modeling`.** When the decision above selected it but the skill is unavailable: read the existing `CONTEXT.md` (or `CONTEXT-MAP.md` and the relevant context's file) before the interview; challenge any term the user or the code uses inconsistently with it as the term comes up; record each resolved term in the glossary the moment it settles; and offer an ADR under `docs/adr/` only for a consequential trade-off, not for every choice. Keep glossary content out of the implementation plan and vice versa — the plan cites terms, it doesn't define them.

### Writing the plan down

The interview only has value if its conclusions survive past the conversation. As branches resolve, keep a running plan document up to date — don't wait until the interview feels "done" to write it, and don't rely on chat history as the record. Phase 2's reviewers and Phase 3's implementers each need a single file to read, not a transcript to reconstruct.

- Create the primary plan at `/tmp/explore-grill-build/<unique-session>/<slug>.md`, where `<slug>` is a short kebab-case feature name. Confirm that a later reviewer can read it before relying on the path.
- If the runtime exposes a writable native plan artifact, mirror the same contents there. Do not treat an undocumented implementation path as a portable default.
- If the plan cannot be shared through either artifact, pass the complete plan text directly to each reviewer and delegate. If no writable artifact is available at all, ask the user for a path.
- A user-specified location overrides these defaults.
- When the build will use a manager loop, end the plan with a checklist grouped into ordered phases; that is the section the loop consumes.

Write enough into it that an independent reviewer — human or AI, with no access to this conversation — could evaluate it cold: the problem being solved, the chosen approach and why (including alternatives that came up during grilling and why they were rejected), the concrete interface/behavior changes, and any open risks or assumptions still on the table. Update it inline as decisions resolve, the same discipline `domain-modeling` uses for `CONTEXT.md` — capture as you go, don't batch.

## Phase 2 — External plan review

Once the plan document feels solid — the interview has resolved its major branches and you'd be comfortable explaining the approach to someone cold — get it checked by reviewers outside this conversation, before writing any code. The point of "outside" is specific: an agent that didn't participate in the interview doesn't share whatever assumptions or momentum built up while you and the user converged. Sunk cost and confirmation bias are conversational phenomena; a reviewer with no conversation to be biased by is immune to them by construction.

Run the strong review against the plan document itself, not the conversation. Run the weak-model probe separately only when a lower tier is selectable.

### Strong-model review

See [references/external-review.md](references/external-review.md) for the eligibility gate. Frame the ask as: review this implementation plan for soundness, feasibility, unstated assumptions, and anything it's quietly assuming that might not hold once it meets the real codebase. This is a review, not a build — make that explicit regardless of which tool ends up handling it.

### Weak-model legibility probe

Separately — in addition to, not instead of, the strong-model review — use a deliberately smaller/cheaper model in the same family only when `delegate_model_select` is confirmed. Hand the probe only the plan document, with instructions to explain it in its own words and flag anything it would need clarified before implementation. If a genuinely lower tier cannot be selected, skip this probe and record why; never misrepresent a same-model review as this check.

The point isn't the weak model's opinion on plan quality — its technical judgment isn't worth much, and that's fine, that's not what it's for. The point is what it *fails to understand*. A strong model can silently paper over an underspecified plan by inferring the missing pieces from general knowledge; a weak model can't do that as well, so its confusion is a direct signal of exactly where the plan document itself is underspecified. Treat every point of confusion it surfaces as a defect in the plan document, not a defect in the weak model's comprehension — the fix is to go rewrite that section of the plan with more explicit detail, not to explain it better to the weak model in that one throwaway session. If the weak model "gets it" cleanly, that's a mildly reassuring signal about the plan's clarity, but absence of confusion is much weaker evidence than presence of confusion — don't over-read a clean pass as proof the plan is good.

This probe is specific to reviewing plans, not diffs — it isn't repeated in Phase 4. A diff is either correct or it isn't; a cheap model's read on that isn't diagnostic the same way an underspecified plan is.

Fold findings from both reviews back into the plan document (same update-inline discipline as Phase 1) before moving on. If either review surfaces a fundamental problem, that's a reason to go back into the interview, not to patch around it during implementation later.

### Before moving to Phase 3

Show the user the plan document plus a short summary of what both reviews found, and confirm you're clear to start building. This doesn't need to be as heavy as the Phase 4 commit gate — it's a "does this still look right to you" checkpoint, not a re-litigation of the whole interview — but don't silently roll from review straight into implementation without it. The entire point of grilling and reviewing was to arrive at a plan the human is actually bought into, and that only holds if they've seen the final version, reviews included.

## Phase 3 — TDD implementation

Implement the reviewed plan test-first.

### Which loop

If `skill_discovery` and `skill_invoke` are confirmed, look for a TDD skill — `tdd` from the companion set, or a harness-native equivalent under another name — and load it. If none is present, the one-time install suggestion from Phase 1 applies (once per session, not once per phase); either way, run the discipline below.

**Red → Green → Refactor**, via vertical-slice tracer bullets (one test, one implementation, repeat — never all tests first, then all implementation). After the last Refactor step for a given slice, rerun the full test suite once more as an explicit final check — treat it as the tail end of Refactor, not a separate ritual.

Where a loaded TDD skill and this workflow disagree, this workflow's loop governs and the skill supplies the test-quality guidance. Concretely: upstream `tdd` places refactoring in the review stage rather than in the loop; here it stays per slice, because Phase 4's external review must see a diff that is already clean. Take from the skill what it is good at — what a test worth keeping looks like, where the seam is that the test observes behavior through, what not to mock. Settle the seams in the Phase 1 plan so the loop doesn't stall on interface shape; if a slice still turns up an unresolved interface, resolve it in the plan document before writing that slice's test rather than following the skill into a further design skill.

For each behavior in the plan, write one failing test, write the minimal code to pass it, and once a slice's tests are all green, refactor — extract duplication, deepen modules, apply SOLID where it is natural — then rerun the whole suite. Writing a batch of tests before any implementation is horizontal slicing; it produces tests that check imagined shape instead of real behavior, and this workflow rejects it regardless of implementation mechanism.

### Manager loop

For a long plan with several ordered phases, use a manager loop when `delegate_persistent` is confirmed. The orchestrator acts as manager, sending one phase at a time to the same implementer, which maintains a checklist page and reports completed items, unresolved work, verification, and its diff. Read [references/manager-loop.md](references/manager-loop.md) before dispatching the first phase for the handoff template, progress page contract, and stall handling. Carry the TDD discipline into every phase message, and have the orchestrator verify each phase's diff and tests before sending the next.

### Fanning out the slices

If the plan breaks into several largely independent tracer-bullet slices, parallelize writes only when `delegate_write_isolated` is confirmed for every slice and the parent has an explicit integration and verification step. Logical independence or disjoint filenames alone is not isolation. If any write-capable delegate shares a workspace, branch, generated output, or test fixtures with another, implement in dependency order instead.

Use per-delegate model tiers only when `delegate_model_select` is confirmed; otherwise use the session default rather than claiming cost or quality tiering.

A starting point for the difficulty → model mapping — adjust this freely, it's a default suggestion, not a fixed rule:

| Slice difficulty | Example | Suggested model |
|---|---|---|
| Mechanical / boilerplate | codegen from a schema, repetitive CRUD wiring, renames, config plumbing | the cheapest/fastest tier available |
| Standard feature work | typical business logic, most tracer-bullet tests | inherit the session default — don't override |
| Architecturally tricky | concurrency, novel abstractions, security-sensitive code, ambiguous interface design, cross-cutting refactors | the strongest tier available |

### The one invariant

Whichever path you used — isolated delegates or direct implementation — you, the orchestrating agent, re-check each slice's output yourself before moving on to the next one or calling the phase done. Delegating a slice delegates the typing, not the responsibility for whether it is right. Read the diff, run the tests, and confirm that it matches that slice of the plan.

This per-slice check is the orchestrator's own same-model read of the diff and tests — never invoke the Phase 2 or Phase 4 external reviewer per slice on your own initiative. The strict external-model review happens exactly once, in Phase 4, over the complete diff, where it can also catch a defect that only shows up across slices — two slices that each look fine on their own but interact in a way neither slice's own check would surface. This cadence is the default, not a cage: an explicit user instruction to externally review a specific slice overrides it, and the Phase 1 interview may propose per-slice external review as an option when a slice is risky enough to justify the cost — but absent either, don't add mid-implementation external reviews yourself.

## Phase 4 — Post-implementation review chain

Before anything gets committed, run three gates, in this order, every time. Each catches a different failure mode; none substitutes for the others.

### 1. Self-review

Read your own (or your delegates') diff directly. Run tests and typecheck. If a diff-review skill is both discoverable and invocable, use it; otherwise review the working diff inline. Unlike the external review below, applying self-review fixes directly is fine because the human commit gate still follows.

### 2. External agent review

Use the same eligibility gate as Phase 2 — see [references/external-review.md](references/external-review.md) — but hand the reviewer the actual diff and touched-files list instead of the plan document. Frame the ask as reviewing real code: correctness, edge cases the tests might have missed, and anywhere implementation drifted from the reviewed plan. Handing over the complete diff in one pass is deliberate — it lets the reviewer catch cross-slice interactions that no per-slice check could see.

Per that reference's ground rule: never auto-apply anything this review suggests. Surface the findings; let the human or an explicit next step decide what happens to them. This rule is absolute here, unlike the self-review step above — this is an outside opinion, not the orchestrator's own already-checked work.

There's no weak-model legibility pass here — that technique specifically catches underspecified *plans*, where a cheap model's confusion is diagnostic of missing detail. A diff is either correct or it isn't; a cheap model's read on that isn't informative the same way.

### 3. Human gate

Summarize, in one place, what was built and what both review passes (self and external) found — including anything you deliberately decided not to act on, and why. Then explicitly ask the human whether it's OK to commit.

Never commit without that explicit go-ahead. This isn't specific to this workflow — it's standing behavior in this environment already — but it's worth restating here precisely because it's the last step, and the last step is exactly where a long, successful run tempts an agent to just wrap up on its own momentum instead of actually asking.

## Cross-cutting invariants

A few things hold across every phase above, worth stating once instead of five times:

- **External findings are never auto-applied** (except the explicit Phase 4.1 self-review carve-out). Whether it's the Phase 2 plan review or the Phase 4 external diff review, an outside agent's output is input to a decision someone makes explicitly — never a patch applied silently.
- **The plan document is the source of truth, not the conversation.** Every phase after Phase 1 reads the plan, not chat history. Keep it current.
- **Delegation doesn't remove verification.** Whatever tier of subagent did the work, the orchestrator checks it before moving on.
- **Capability gates outlive the phase that ran them.** A companion skill loaded mid-workflow inherits this session's confirmed/unavailable marks; its own instructions to delegate, spawn, or invoke don't re-open a gate that was closed in the runtime check.
- **Scale effort to the task.** See Scope, above — this doesn't stop mattering once you're mid-flow.

Use a runtime adapter only when one exists and its described capabilities are confirmed in the current session. See `references/harness-adapters/` — `claude-code.md`, `codex.md`, `opencode.md`, and `hermes-agent.md`. Record the evidence required before adding or changing an adapter in `references/harness-adapters/README.md`; an adapter is a mapping, not a fallback specification.
