# Codex Harness Mechanism

This file is the mechanism behind the operational model in SKILL.md — how each layer described there is actually built, down to the byte and millisecond limits, plus the complete rejection-string table that SKILL.md only summarizes as keyword triage.
Read SKILL.md first for the mode matrix, the fast triage table, and the two playbook sections; come here when those don't resolve what you're seeing, or when you need an exact limit, constant, or the full string list.
Evidence for every claim in both files lives in `references/provenance.md`, keyed by a re-greppable fragment rather than a commit — treat figures here as current behavior, not as a historical record.

## Layer 0 — governance ceiling

Set before the session; neither the agent nor the user can raise or lower it mid-run. SKILL.md states the operational shape of each item below; this is the detail it doesn't have room for.

- **The "force exact value" set's actual keys**: beyond approval policy, sandbox mode, and web-search mode, the same mechanism reaches `sqlite_home`, `log_dir`, `model_catalog_json`, `check_for_update_on_startup`, `allow_login_shell`, and the Windows `sandbox_private_desktop` flag. Most of these are bookkeeping, but two aren't — `allow_login_shell` and the Windows private-desktop flag change exec semantics directly, not just which options a UI shows.
- **Managed hooks' auto-trust path fails closed**: a hook shipped inside a workspace plugin installed or updated from a marketplace under the active account gets its content hash auto-recorded as trusted right after a successful plugin refresh — a second, non-manual route to "trusted" status alongside manual grants. If the trust-record write fails, or the account changes mid-process, this route fails closed rather than trusting anyway.
- **The model catalog's per-model `tool_mode` field is read unconditionally before any local feature flag** — there is no branch where local config overrides a catalog value. The shipped catalog currently sets `tool_mode: code_mode_only` for a handful of model slugs (`gpt-5.6-sol`, `terra`, `luna`); the CLI's current default model carries neither catalog field, which is why most sessions never see this. See "Code mode" under §6 for the runtime mechanism this leads to.

## 1. What the agent sees before acting

The harness assembles the agent's entire world. Key injection layers, in rough order:

- **System prompt**: chosen per model; overridable by config; persisted across resume. Mid-thread model or personality switches do NOT rewrite it — they inject `<model_switch>` / `<personality_spec>` developer messages that retrain the agent in place.
- **Permissions announcement**: a developer message wrapped in `<permissions instructions>` states the sandbox mode, approval policy, writable roots, denied reads, and pre-approved command prefixes. It explicitly teaches which escalations are futile, e.g. "Approval policy is currently never. Do not provide the `sandbox_permissions` for any reason, commands will be rejected." and "NEVER provide a prefix_rule argument for destructive commands like rm." Re-injected on any policy change. These are default strings, not guaranteed: a server-supplied model catalog can override the announcement text for any approval policy, and a separate catalog field can independently override the sandbox-mode section.
- **Environment context**: a user-role `<environment_context>` fragment with cwd, shell, date, timezone, network allow/deny domain lists, and filesystem access entries. Only diffs are re-sent mid-session — a bare new cwd can appear with no explanation. The sandbox and network policy are disclosed up front here, not just enforced later.
- **AGENTS.md**: collected from project root down to cwd (an `AGENTS.override.md` beats `AGENTS.md` per directory), concatenated with separators, under a total byte budget (`project_doc_max_bytes`, default 32 KiB, configurable). The file straddling the budget is byte-truncated mid-file, later files dropped whole — nothing in the delivered text marks the cut, and the only trace of the cut existing at all is a server-side log line the model never sees. Changes are re-injected with explicit replace/expire notices.
- **Marker protocol**: every harness-injected user-role fragment carries start/end markers (`<permissions instructions>`, `<environment_context>`, `<external_…>`, `<codex_internal_context …>`, `# AGENTS.md instructions`). The human UI hides these; the markers are the agent's only signal that text is harness-authored rather than typed by the user.
- **Trust labeling**: host-provided context arrives either as user-role `<external_KEY>value</external_KEY>` (untrusted — quarantined, not instructions) or as developer-role `<KEY>value</KEY>` (application-trusted). Values over ~1,000 tokens are middle-truncated with a literal `…N tokens truncated…` marker.
- **Skills**: the skills list gets ~2% of the context window; descriptions are capped, then shortened, then whole skills are dropped by scope priority when over budget. A `$skill-name` mention injects that skill's entire body as a `<skill>` fragment — but only when exactly one enabled skill matches; ambiguous mentions are silently skipped with no error. Note what this does *not* pull in: only the skill's own top-level body is injected, so a `references/` tree ships with the skill at zero injection cost and is read on demand with file tools. This is the `$mention` path only. Skills are also reachable as ordinary tool calls with a different budget and a different visibility boundary — see "Skills delivery" under §6.
- **Tool menu**: recomputed for every sampling request. Deferred tools are invisible until discovered via tool search. Oversized tool schemas — over 5,000 bytes, a round decimal threshold, not 5 KiB — are compacted progressively in up to four stages, each attempted only if the schema is still over budget after the last one: strip descriptions, drop schema definitions, collapse deeply-nested objects toward the root, then prune schema compositions (constructs like allOf/oneOf/anyOf). There is no marker recording that compaction happened, or which stage it stopped at.
- **Reminders**: periodic timestamps ("It is YYYY-MM-DD HH:MM:SS UTC."), a token-budget warning when nearing compaction, and cross-thread budget notices as thresholds are crossed.
- **Goal steering**: hidden fragments between turns push back on scope-shrinking ("Do not substitute a narrower, safer, smaller... solution") and order wrap-up when budget runs low. Objectives are XML-escaped and labeled as user-provided data to blunt prompt injection.
- **Hooks at intake**: prompt-submit and session-start hooks can inject developer-role context, or veto the turn entirely — a blocked prompt never reaches the model at all.
- **Fragment count**: the harness implements roughly 40 distinct injectable context fragments in total — a few more raw implementation sites exist, but some of those are test-only fixtures or duplicate wiring rather than a distinct fragment. The bullets above are the load-bearing ones; two clusters this document had never named before are a realtime/voice fragment family and a family of `Legacy*Warning` fragments. Worth knowing specifically: `approved_command_prefix_saved` and `network_rule_saved` fire after a proposed prefix or network rule is actually persisted, telling the model in-band that it happened. That narrows the self-escalation claim in §2 that "suppressed suggestions give the model no feedback" — that claim is only about suggestions that get suppressed. A rule that does get saved is echoed back through one of these two fragments on a later turn.

## 2. What happens when the agent acts

### Tool dispatch

- Unknown tool name → `unsupported call: {tool}` returned as a failed tool result; the turn continues.
- Parallel tool calls return in emission order regardless of completion order; a tool not marked parallel-safe takes an exclusive lock and serializes against everything.
- **PreToolUse hooks** run before dispatch. A hook can veto (`Command blocked by PreToolUse hook: {reason}. Command: {command}`) — or silently rewrite the tool's input. The rewritten command executes; the agent only sees the output of what actually ran, not what it asked for.

### Command classification (exec policy)

Every shell command is classified allow / prompt / forbidden before anything spawns, and the worst matching decision wins — one forbidden rule overrides any allow.

- `bash -lc` scripts are parsed with a real bash grammar. Only plain word-commands joined by `&& || ; |` are decomposed and checked segment by segment. Any subshell, redirection, substitution, control flow, or parse error forfeits the built-in per-command auto-approval — the script becomes one opaque command vector the safelist heuristic won't recognize, though an explicitly configured prefix rule (e.g. anchored on `bash -lc`) can still match the whole vector and decide it. This closes the "safe-cmd && unsafe-cmd" smuggling hole.
- A read-only safelist covers common inspection commands (ls, cat, grep, head, rg, find without -exec/-delete, git restricted to status/log/diff/show/branch with unsafe global options denied).
- `rm -f`/`-rf` (even via sudo, even inside a parsed sequence) forces a prompt — or outright rejection when prompting is disabled. Detection is deliberately broad: it also catches forced rm hidden inside `env`-wrapped invocations, `trap ... EXIT` bodies, pipelines, `if`/`for`/`while` control flow, `$(...)`/backtick substitution, nested `bash -c`/`sh -c`, and force flags placed after the operand (`rm /tmp/x -f`) — not just the direct/sudo form. A closed loophole: under policy `never` with the sandbox explicitly disabled, a dangerous-rm match used to be silently allowed; it is now always forbidden, with its own rejection string: `` `{command}` rejected: rm -f style commands are not permitted. Use a safer approach ``.
- When policy forbids prompting, would-be prompts convert to rejections with exact strings like `approval required by policy, but AskForApproval is set to Never`.
- A forbidden command never spawns: `` `{command}` rejected: policy forbids commands starting with `{prefix}` ``.

### The approval gate

When a prompt is required, the tool call suspends on a channel until a decision arrives. Precedence: permission-request hooks → guardian LLM reviewer → human.

- Hooks can allow or deny without the human ever seeing a prompt; an allow is indistinguishable from user approval.
- The guardian (when enabled) is an LLM judge; denial reads `This action was rejected due to unacceptable risk.` plus a rationale.
- Human denials are normalized to exactly `exec command rejected by user` / `patch rejected by user`.
- Client/transport failures during approval fail closed to a denial — indistinguishable from a human saying no.
- **The session-approval cache key has five fields**: environment id, canonicalized command, cwd, the sandbox permission profile, and a separate optional additional-permissions profile. All five must match for a cached approval to be reused, so the two permission profiles are independent conditions rather than one. Changing directory invalidates an approval. The command field is canonicalized before it becomes part of the key — wrapper-path variants collapse together (`/bin/bash -lc X` and `bash -lc X` hash the same) and recognized bash and PowerShell scripts are rewritten to a canonical placeholder form — so commands that read differently can share a single approval, which is the opposite of an exact-match cache.
- Choosing "abort" on any approval prompt tears down the whole turn, not just that call.

### Self-escalation is scripted away

- Requesting escalated permissions when the policy doesn't allow it earns an immediate corrective rejection: `approval policy is {policy}; reject command — you should not ask for escalated permissions if the approval policy is {policy}`.
- The model may propose a reusable allow-prefix rule, but interpreter prefixes are banned, and only an explicit user decision persists the rule. The banned list is large (88 entries, up from an earlier 46) and covers essentially every shell (`bash`/`sh`/`zsh`/`dash`/`ksh`/`fish`/`cmd`/`powershell`/`pwsh`), interpreter (`python3`, `node`, `ruby`, `perl`, `php`, `lua`, `Rscript`, `julia`, `deno`, `bun`), and package-runner (`npm run`, `pnpm run`, `yarn run`) invocation, plus `rm` and `sudo` themselves — not just a handful of illustrative examples.
- A one-shot startup migration enforces this retroactively: on first launch of a version that ships the enlarged banned list, any previously-saved custom allow-prefix rule in the user's rules file that now matches an entry on that list is silently deleted, and a marker file then records completion so the migration never re-runs. A prior "always allow" for a shell/interpreter/`rm`/`sudo` prefix can vanish across an upgrade with no in-band notice.
- Suppressed suggestions (ones that get banned or otherwise not persisted) give the model no feedback at all. Rules that do get persisted are the opposite case: the next turn carries an `approved_command_prefix_saved` or `network_rule_saved` context fragment confirming exactly what was saved — see the fragment-count note in §1.

### apply_patch

- Patches are intercepted from the shell before execution. A raw patch without the wrapper gets `patch detected without explicit call to apply_patch...`.
- The patch grammar is checked and every target chunk is verified against the real filesystem before any write; failure aborts the whole patch atomically.
- Context matching is fuzzy (four passes down to Unicode punctuation normalization) and applies without telling the model its context lines were inexact.
- Writes outside writable roots hit a safety gate: prompt, or `patch rejected: writing outside of the project; rejected by user approval settings`.

### A second check at exec time (opt-in backend only)

When the zsh-fork/execve-wrapper backend is active, every `exec()` of every binary — including ones launched by scripts — is re-checked against policy using the resolved absolute path; a script cannot launch what its text hid. Denials appear inside the command's own output as `Execution denied: {reason}` with exit 1, and the command's timeout clock pauses while an approval prompt is pending. This backend requires Unix, off-by-default feature flags (`shell_zsh_fork` / `unified_exec_zsh_fork`, under development), the user's shell configured as zsh, and a resolvable wrapper binary. In a default configuration it is NOT active — there the OS sandbox applies its policy once at spawn (inherited by children at the kernel level) with no per-exec re-evaluation against the command-classification engine.

## 3. How execution is confined

- **Sandbox modes**: `read-only` / `workspace-write` (cwd + declared roots + tmp) / `danger-full-access` / external (delegated to a container). Enforced by transparent argv rewriting: macOS Seatbelt (deny-by-default profile), Linux bwrap mount namespace + seccomp (network syscalls → EPERM), Windows restricted token + firewall filters — when the Windows sandbox backend is actually the one running.
- **Windows does not refuse to run unsandboxed — it degrades.** The Windows sandbox backend's feature is flagged at stage `Removed` with `default_enabled: false`, so a mainline Windows build has no sandbox backend to construct in the first place; the degrade path is the normal one, not an edge case triggered by some failure. In that state the harness downgrades the default built-in profile from workspace-write to read-only and pushes non-safelisted commands to prompt or forbid — but a known-safe, non-complex command is deliberately allowed to run with no OS jail at all. Separately, the `anyhow::bail!` errors the Windows sandbox crate raises (for example, refusing to build a sandbox for a profile that demands full-disk write access it cannot enforce) fire during sandbox construction, before any question of running a command arises. They are provisioning failures, not exec-time refusals — reading one as "Windows blocked this command" is a category error; it blocked building the jail, not the command.
- Env markers are partial: `CODEX_SANDBOX_NETWORK_DISABLED=1` is set on every platform exactly when the network policy is restricted; `CODEX_SANDBOX=seatbelt` exists only under macOS Seatbelt (its sole value) — Linux and Windows sandboxes set no backend marker, so its absence proves nothing.
- **Protected metadata**: `.git`, `.agents`, `.codex` are carved out of writable roots — hooks/config self-escalation is blocked. On Linux a watcher even deletes protected paths created during a run and forces exit 1 with `sandbox blocked creation of protected workspace metadata path …`. A sandbox entry pointing at a path that doesn't exist is skipped rather than erroring, which is what keeps `.git` protection well-behaved in a directory that isn't actually a git repository.
- **Network** is proxy-mediated and fail-closed; a blocked host surfaces as `Network access to "{host}" is blocked by policy.` An allowlist entry that is an explicit IP literal or the literal `localhost` now lets loopback/private destinations through; without such an entry, loopback and private ranges are still blocked unconditionally regardless of the rest of the allowlist.
- **Denial detection is keyword-based, and the list is exactly seven terms**: `operation not permitted`, `permission denied`, `read-only file system`, `seccomp`, `sandbox`, `landlock`, `failed to write file`. Alongside the keyword match, a small set of exit codes (`2`, `126`, `127`) triggers a quick-reject path on its own, and on Linux a process terminated by `SIGSYS` is treated as a sandbox denial on its own too. Nonzero exit plus any of the above is classified as a sandbox denial — which can false-positive: a command that legitimately prints "permission denied" as ordinary output may be treated as sandbox-blocked.
- **The escalation loop**: a classified sandbox denial may earn exactly one approval-gated retry without the sandbox ("command failed; retry without sandbox?"). Never under `never` — zero exceptions. Not under `on-request` either, except two prompt-gated escape hatches: apply_patch may prompt for an unsandboxed retry, and a denial attributable to an active managed-network policy may prompt for re-adjudication (staying inside the OS jail when deny-read restrictions exist). The model cannot trigger this retry and cannot tell it happened: on approval it just sees the second run's success.
- **Limits, shell exec**: default timeout 10 s (process group SIGKILLed, exit forced to 124, partial output kept). stdout, stderr, and the "aggregate" combined view are not three independent budgets — all three are capped against the same 1 MiB constant; aggregate is a different accounting path over that same limit, not a bigger one. Under contention the split is uneven: stdout gets a third of the remaining budget, stderr gets the other two-thirds.
- **Limits, unified interactive exec**: a call yields after its wait window and can return a process id while the process keeps running. Initial exec waits 10 s by default. A caller may request a longer per-poll wait for `write_stdin` polling, configurable up to 300 s by default. Separately: the poll argument's own default is 250 ms, and an empty poll (nothing new to return) is clamped up to a 5 s floor regardless of the requested value — 5 s is a lower bound on empty polls, not a default wait time. A distinct constant caps non-empty writes at 30 s — a bound the previous version of this reference omitted entirely. These are wait bounds, not process lifetimes.
- **Windows process containment**: pipe, ConPTY, and sandboxed child processes are placed in a Job Object, so a cancel, a timeout, or an explicit stop now brings down the whole process tree together. This weakens the "background processes may still run" caveat in §5 specifically on Windows — see the note there.
- **Headless runs** (`codex exec`) default the approval policy to never, so would-be prompts normally become deterministic rejections. When the resolved approvals reviewer is AutoReview, the headless never override may be removed and the configured approval policy rebuilt.
- Environment hardening strips all `LD_*`/`DYLD_*` variables and clears env for internal helpers — preload tricks and inherited secrets silently vanish.

## 4. How results are shaped on the way back

- **Double truncation**: tool output is middle-cut to the model's token budget (`…{N} tokens truncated…` marker, head and tail kept), then re-truncated again when recorded into history — oversized output never survives into later prompts.
- **Framing**: every exec result is wrapped with `Exit code: N`, `Wall time: N seconds`, and `Output:` headers; timeouts prepend `command timed out after {N} milliseconds`.
- **No output scrubbing happens at this stage.** Codex ships a credential vault (`codex-secrets`, primarily an OS-keyring-backed store) and a regex-based secret sanitizer, but the sanitizer has exactly three call sites — OAuth token handling, memory-writing, and auth storage — and none of them sit in the exec or tool-output pipeline. Nothing in this result-shaping stage redacts secrets out of command output on the way back to the model.
- **PostToolUse hooks** can retroactively reject a completed result (side effects already happened; the model sees the hook's feedback instead of the real output), swap a successful result's model-visible text for the hook's feedback message (the original output is retained internally; hooks cannot forge an arbitrary structured tool response), or inject extra context as separate developer-role messages.
- **Hook output over ~2,500 tokens** is spilled to a file; the visible text ends with `Full hook output saved to: {path}` — the agent can read it back with file tools.
- **History repair**: before every request the harness synthesizes missing tool outputs, drops orphans, and silently trims old assistant text to token budgets — with no marker. Separately, when the model's declared modalities don't support image or audio input, unsupported content is proactively replaced with placeholder text ("image content omitted because you do not support image input" / "audio content omitted because you do not support audio input") — this is unconditional on modality, not a reaction to an API error. An actual API rejection of an invalid image used to trigger a silent retry with the image swapped for literal "Invalid image" text; that retry-and-rewrite path has been removed — a rejected image now ends the turn immediately with a user-visible error ("Invalid image in your last message. Please remove it and try again."), no silent retry, no history rewrite.

### Rejection-string vocabulary

Observed internal UI/test strings — not a stable API; frontends may reword them, and the list is not exhaustive.

Match on the literal fragment between placeholders, never on the whole templated string — the placeholder names shown here are for readability and don't always match the source's internal field names. For example, this document writes `unsupported call: {tool}`, but the source's own template uses a differently-named placeholder internally; grepping the fragment before the placeholder (`unsupported call: `) still finds it, grepping the literal string with `{tool}` in it does not. The same trap applies to `` `{command}` rejected: policy forbids commands starting with `{prefix}` `` (match on `rejected: policy forbids commands starting with`), `aborted by user after {secs}s` (match on `aborted by user after`), `command timed out after {N} milliseconds` (match on `command timed out after`), and `Network access to "{host}" is blocked by policy.` (match on `is blocked by policy`).

Denial reasons are propagated rather than fixed: a denial carries a reason string identifying its source — e.g. `rejected by configuration` (hook), `rejected by user` (human), the guardian's full risk rationale, `approval request aborted` (abort), `approval request failed` (transport failure) — so read the reason to see which layer denied instead of assuming one generic string. The list of reasons is open-ended; callers supply the text.

| The agent sees | What actually happened |
|---|---|
| `exec command rejected by user` | Human, hook, or failed client denied the approval prompt |
| `patch rejected by user` | Same, for apply_patch |
| `` …rejected: policy forbids commands starting with… `` | A forbidden prefix rule matched; command never spawned |
| `` …rejected: rm -f style commands are not permitted. Use a safer approach `` | Dangerous-rm heuristic matched (env/trap/pipeline/control-flow/substitution/nested-shell aware); command never spawned |
| `approval required by policy, but AskForApproval is set to Never` | Prompt suppressed by policy; nothing was asked |
| `approval required by policy, but AskForApproval::Granular.sandbox_approval is false` | Granular policy has sandbox-escalation prompts turned off; nothing was asked |
| `approval required by policy, but AskForApproval::Granular.rules is false` | Granular policy has rule-based prompts turned off; nothing was asked |
| `approval policy is …; reject command — you should not ask for escalated permissions…` | The agent requested escalation in a mode that forbids it |
| `This action was rejected due to unacceptable risk.` | Guardian LLM denied it; no human was asked |
| `Command blocked by PreToolUse hook: …` | A configured hook vetoed the call pre-execution |
| `Execution denied: …` (inside command output, exit 1) | Per-exec policy check blocked a binary launch (zsh-fork backend only) |
| `unsupported call: {tool}` | The tool doesn't exist in this step's tool list |
| `user rejected MCP tool call` | MCP approval denied; the server was never contacted |
| Output containing `operation not permitted` / `permission denied` / `read-only file system` / `seccomp` / `sandbox` / `landlock` / `failed to write file` | OS sandbox denial, classified by keyword match and surfaced as-is (no retry was offered) |
| `command failed inside sandbox with exit code {N}` | Sandbox denial with empty output |
| `patch detected without explicit call to apply_patch…` | A raw patch was sent outside the `apply_patch` wrapper; resend it as a real `apply_patch` call |
| `patch rejected: writing outside of the project; rejected by user approval settings` | apply_patch's target path fell outside the writable roots |

This table is longer than SKILL.md's triage version because it also carries the two Granular-specific strings and the two apply_patch-specific strings verbatim, alongside the keyword-level view SKILL.md needs for fast matching.

Two things about how these actually arrive, both observed in a live `codex exec` run rather than read out of the source:

**Policy rejections are nested inside a wrapper, OS denials are not.** A rejection reaches the model wrapped in the spawn error that carried it — `` exec_command failed for `/bin/zsh -c '…'`: CreateProcess { message: "Rejected(\"approval required by policy, but AskForApproval is set to Never\")" } `` — so the reason string is a substring of a Rust-debug-formatted blob, never a line of its own. An OS-jail denial gets no wrapper at all: it is the command's own stderr, verbatim (`touch: /tmp/x: Operation not permitted`). That asymmetry is why keyword matching beats line matching, and why sandbox denials are the ones most easily mistaken for ordinary tool errors.

**The forced-rm string is a reason substitution, not a separate gate.** The rejection path computes a fallback reason first and only replaces it when the dangerous-command heuristic still reports a forced-rm at that point; otherwise the fallback survives. In practice a shell-wrapped `rm -rf` under approval policy `never` produced the generic `approval required by policy, but AskForApproval is set to Never` reason, not the rm-specific one. Treat the rm string as a signal that a forced-rm was positively identified — not as the expected failure mode for every `rm -rf`.

## 5. Cross-cutting loops

- **Stream retry, silent to the model**: transport/API errors replay with exponential backoff, then one permanent WebSocket→HTTPS fallback (websocket-capable providers only). Each retry rebuilds the prompt from current history — the model observes nothing, though the user's frontend does receive warning/stream-error events (including a one-time "Falling back from WebSockets to HTTPS transport" notice).
- **Auto-compaction rewrites memory**: at token thresholds (or when the model calls the context-window tool — which is only a request), the harness has the model summarize its own progress, then replaces the entire history with that summary plus freshly re-injected permissions/environment/AGENTS.md. In the new window, prior work is introduced as "Another language model started to solve this problem and produced a summary…" — the agent's own past presented as a stranger's, all intermediate tool traffic gone. On overflow, oldest items are silently dropped one at a time. An opt-in refinement exists, gated behind a token-budget feature flag and an explicit configured prompt: a fallback phase can fire before the real rollover, reserving extra buffer tokens and injecting the configured prompt exactly once as a bare message — one chance for the model to write down state before compaction actually replaces history.
- **Interruption**: aborted tool calls become synthetic outputs (`aborted by user after {secs}s`), and the next turn opens with a `<turn_aborted>` marker warning that aborted commands may have partially executed and background processes may still run. On Windows this is now weaker than it sounds: pipe/ConPTY/sandboxed children live inside a Job Object (§3), so a cancel or timeout usually takes the whole process tree down with it rather than leaving orphans running.
- **Stop hooks — the agent may not be allowed to stop**: when the model ends its turn, a configured stop hook can reject the stop; its reason is injected as a new prompt and sampling resumes. Hook timeouts fail open (a hung hook never blocks). A hook that exits normally without reading all of its stdin is tolerated too: the resulting broken pipe is ignored, and the harness uses the hook's actual exit code and output rather than treating the broken pipe itself as a failure.
- **Session teardown hooks**: a `SessionEnd` hook runs fire-and-forget during session shutdown, after exec/MCP/code-mode teardown — it has no veto capability at all, defaults to a 1 s timeout hard-capped at 3 s, and fires only for the root session, not subagent/`ThreadSpawn` sessions. Its `async: true` config flag is currently a no-op — it still runs synchronously.
- **Mid-stream preemption**: queued user input can cut the model's response short at an item boundary and land between tool rounds unbidden.
- **Budget hard stops**: once the cross-thread budget is exhausted, turns terminate with a hard error regardless of task state.
- **Review mode**: review mode runs in a locked-down delegate (approval forced to never, web search and collaboration tools disabled, and a rubric that requests findings JSON). The output is parsed best-effort as JSON, with plain-text fallback.

## 6. Subsystems the operational layer only summarizes

SKILL.md's Layer 0 and "What you actually have by default" sections give the operational summary for the subsystems below — how to tell they're active, and the one or two things worth doing differently. This section is the mechanism behind that summary, organized by subsystem rather than by pipeline stage.

### Code mode

In code mode the model writes JavaScript instead of making tool calls. The script is evaluated as an async ES module in a fresh V8 isolate — no Node, no filesystem, no network, and `console` is deleted from the global object. Nested tools are exposed as `tools.foo(args)` promises, and a companion `wait` tool resumes a suspended cell. Nested calls dispatch through the same router as direct calls, so every gate in this document is applied to each one individually; a denied or failed nested call surfaces to the script as a **rejected promise it can catch within the same turn**, rather than as a tool result the model reads on the next turn. Runaway scripts are stopped by V8 isolate termination, not an OS timeout. In `CodeModeOnly` specifically, tools outside `exec`/`wait` are hidden from the model-visible menu outright rather than routed through the script, except those explicitly marked direct-model-only or excluded by namespace. What puts a model into code mode is the catalog reading order described in Layer 0 above; how to recognize it mid-session is in SKILL.md.

### Subagents and agent mail

Two parallel subagent systems exist. V1 — `spawn_agent`, `wait_agent`, `close_agent`, `resume_agent`, `send_input` — is stable, default-enabled, and therefore present in every ordinary session, limited only by a spawn depth that defaults to 1. `send_input` is the "mail" half of that set: it delivers new text to an already-running subagent rather than spawning a new one. Beyond that:

- Depth-1 limits how many levels deep a spawn chain can go, not how many siblings exist at any one level — width isn't limited the same way.
- Codex ships built-in agent roles, but right now they're placeholders rather than active behavior: one shipped role's config is an empty file, and another exists in source but is commented out of the built-in role list — neither currently changes anything by existing. What is fully live is the underlying mechanism a user-defined role plugs into: a role can carry its own model, reasoning effort, sandbox mode, and approval policy, so a spawned agent is not guaranteed to inherit the permissions of the agent that spawned it.

### Skills delivery

Skills reach the model three ways: the budgeted catalog listing, a `$skill-name` mention that injects the full body as a `<skill>` fragment, and the `skills.list` / `skills.read` tools. An explicit-only executor skill is omitted from `list` but still fetchable through `read`, so the listing is not the full set of what is reachable. Three further mechanics:

- The instructional text that teaches the model how to invoke a skill it just discovered is itself part of the render path and can change independently of the skill's own content — treat its exact phrasing as no more stable than any other string in this document.
- The primary `$mention` path's ~2% context-window budget (§1) is uncapped in absolute terms — it can still grow with the window. The tool-call path (`skills.list`/`skills.read`) carries its own hard ceiling instead: 4,000 tokens, independent of window size.
- When either path is over budget, description-shortening is at least announced with a warning string saying so. A separate reshape is not announced at all: long or repeated skill paths can be silently aliased down to short placeholder tokens (`r0`, `r1`, …) — the same unmarked pattern as the tool-schema compaction in §1.

### Plugins as a tool and hook source

A plugin manifest is not just a marketplace listing — it can declare both `mcp_servers` and `hooks` directly, so installing a plugin can add tool surface and hook coverage in the same step, including feeding the hook auto-trust path described in Layer 0.

- A marketplace-level allowlist can deny an installed plugin's MCP tools entirely (deny-all), independent of whether the plugin itself is otherwise trusted.
- Four distinct context fragments exist purely to describe plugin state to the model — installed apps, available plugins, recommended plugins, and a general plugin-instructions fragment — none of which are named anywhere else in this document; they sit alongside the fragments enumerated in §1.
- The model has a dedicated tool to request that a plugin be installed on its behalf, rather than only being able to describe the need in text.
- Plugin script attribution — crediting which script inside a plugin performed an action — is an analytics/UI concern only. It doesn't change gating and isn't covered further here.

### Collaboration / Plan mode

Plan mode is the clearest example in this document of an instruction that reads like a wall but isn't one.

- The mode's template tells the model, in plain language, that it must not perform mutating actions. That instruction lives entirely in prompt text.
- There is no dispatch-side enforcement of it: the code paths that actually route `exec` and `apply_patch` calls to execution have no branch that checks which collaboration mode is active. Plan mode's restriction is enforced by the model choosing to comply, exactly like any other instruction in this document that isn't backed by a gate.
- Contrast this with `update_plan`, which is hard-blocked in code — a genuine gate, not a prompted convention. The gap between these two is the thing this whole section exists to teach: read every instruction and ask whether a gate backs it, because some don't.
- The `<collaboration_mode>` fragment that would carry the "no mutating actions" instruction is not even sent in a default session — a plain default session gets `<permissions instructions>` but no collaboration-mode fragment at all. Plan mode's soft restriction only comes into play once collaboration mode has been explicitly turned on in the first place.
