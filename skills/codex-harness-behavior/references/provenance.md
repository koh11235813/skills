# Provenance ledger

Evidence for every load-bearing claim in `SKILL.md` and `references/mechanism.md`, so the next update is a diff against this table rather than a re-reading of the prose.

**Pinned:** codex-rs `main` @ `4c43465133`, 2026-07-25.

Paths are relative to `codex-rs/` in the [openai/codex](https://github.com/openai/codex) repository.

The **match on** column is what to `rg` for. It is deliberately *not* the full string as quoted in the prose: most quoted strings are `format!` templates whose placeholder names differ from the source (the docs say `unsupported call: {tool}`; the source says `format!("unsupported call: {tool_name}")`). Searching the whole template returns zero hits for claims that are perfectly correct. **Always match on the literal fragment between placeholders, or on the constant/type name.**

---

## Command classification (exec policy)

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Banned allow-prefix list has 88 entries | mechanism §2 | `core/src/exec_policy.rs:53-142` | `BANNED_PREFIX_SUGGESTIONS` |
| Forbidden prefix never spawns | SKILL triage, mechanism §2 | `core/src/exec_policy.rs:1064` | `rejected: policy forbids commands starting with` |
| Dangerous-rm heuristic forbids outright | SKILL triage, mechanism §2 | `core/src/exec_policy.rs:1094` | `rm -f style commands are not permitted` |
| Prompt suppressed under `never` | SKILL triage, mechanism §2 | `core/src/exec_policy.rs:45` | `approval required by policy, but AskForApproval` |
| Two Granular-specific rejections exist | mechanism §4 table | `core/src/exec_policy.rs:45-49` | `Granular.sandbox_approval is false` |
| Windows-without-backend allows safe commands unsandboxed | SKILL mode matrix, mechanism §3 | `core/src/exec_policy.rs:751-765` | `windows_managed_fs_restrictions_without_sandbox_backend` |
| Escalation request in a forbidding mode is scripted-rejected | SKILL triage, mechanism §2 | `core/src/tools/handlers/shell.rs:136` | `you should not ask for escalated permissions` |
| One-shot migration strips banned saved rules | mechanism §2 | `execpolicy/src/sandbox_migration.rs` | `strip_banned_allow_rules` |

## Approval gate

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Approval cache key is 5 fields, not the command alone | SKILL inside playbook, mechanism §2 | `core/src/tools/runtimes/shell.rs:95-101` | `struct ApprovalKey` |
| Command is canonicalized before keying | SKILL inside playbook, mechanism §2 | `core/src/command_canonicalization.rs:14-38` | `__codex_shell_script__` |
| Denial reasons are propagated, not fixed | SKILL triage, mechanism §4 | `core/src/tools/approvals.rs:173,184` | `rejected by configuration` |
| Guardian denial wording | SKILL triage, mechanism §4 | `core/src/guardian/review.rs:621` | `rejected due to unacceptable risk` |
| Human denial normalized | SKILL triage, mechanism §4 | `core/src/tools/events.rs:443,445` | `exec command rejected by user` |
| Abort tears down the whole turn | mechanism §2 | `core/src/session/handlers.rs:386-401` | `ReviewDecision::Abort` |
| MCP denial never contacts the server | SKILL triage, mechanism §4 | `core/src/mcp_tool_call.rs:267` | `user rejected MCP tool call` |

## OS sandboxing

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| **Windows downgrades workspace-write to read-only** | SKILL mode matrix, mechanism §3 | `core/src/config/permissions.rs:48-59` | `default_builtin_permission_profile_name` |
| …and a test asserts exactly that | — | `cli/src/debug_sandbox.rs` | `downgrades to read-only when the Windows sandbox is disabled` |
| Windows sandbox backend ships disabled | SKILL mode matrix, mechanism §3 | `features/src/lib.rs:1037-1047` | `experimental_windows_sandbox` |
| `CODEX_SANDBOX=seatbelt` is macOS-only | SKILL inside playbook, mechanism §3 | `core/src/sandboxing/mod.rs:149-152` | `CODEX_SANDBOX_ENV_VAR` |
| `CODEX_SANDBOX_NETWORK_DISABLED` on every platform | SKILL inside playbook, mechanism §3 | `core/src/spawn.rs:78-80` | `CODEX_SANDBOX_NETWORK_DISABLED` |
| Protected workspace metadata is deleted and forces exit 1 | mechanism §3 | `linux-sandbox/src/linux_run_main.rs:1149` | `sandbox blocked creation of protected workspace metadata path` |
| Seatbelt profile is deny-by-default | mechanism §3 | `sandboxing/src/seatbelt_base_policy.sbpl:8` | `(deny default)` |
| Linux network syscalls return EPERM via seccomp | mechanism §3 | `linux-sandbox/src/landlock.rs:250-253` | `SeccompAction::Errno` |
| Denial detection is 7 keywords + exit codes + SIGSYS | SKILL triage, mechanism §3 | `sandboxing/src/denial.rs:14-22` | `landlock` |
| The single retry-unsandboxed gate | mechanism §3 | `core/src/tools/orchestrator.rs:532` | `retry without sandbox` |
| Blocked host wording | mechanism §3 | `core/src/tools/orchestrator.rs:386` | `is blocked by policy` |
| `LD_*` / `DYLD_*` stripped | mechanism §3 | `process-hardening/src/lib.rs:60,79,99` | `remove_env_vars_with_prefix` |
| Explicit loopback allowlist entries now connect | mechanism §3 | `network-proxy/src/connect_policy.rs:87,102,124` | `allows_non_public_target` |
| Missing sandbox paths are skipped, not materialized | mechanism §3 | `protocol/src/permissions.rs:179,197-207` | `missing_path_behavior` |
| Windows kills process trees via job objects | mechanism §3, §5 | `utils/pty/src/win/job.rs` | `JobObject` |

## Limits and truncation

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Exec timeout 10 s, exit forced to 124 | mechanism §3 | `core/src/exec.rs:58,65` | `DEFAULT_EXEC_COMMAND_TIMEOUT_MS` |
| stdout, stderr, and aggregate share one 1 MiB constant | mechanism §3 | `utils/pty/src/lib.rs:12`, `core/src/exec.rs:76,749-768,886-894` | `DEFAULT_OUTPUT_BYTES_CAP` |
| Unified-exec wait constants | mechanism §3 | `core/src/unified_exec/mod.rs:64-69` | `MIN_EMPTY_YIELD_TIME_MS` |
| Empty polls clamp to `[5 s, configured max]`; non-empty capped at 30 s | mechanism §3 | `core/src/unified_exec/process_manager.rs:755-757` | `clamp(MIN_EMPTY_YIELD_TIME_MS` |
| Tool-schema compaction is 4 progressive passes over a 5,000-byte threshold | SKILL default surface, mechanism §1 | `tools/src/json_schema.rs:222,240-245` | `prune_schema_compositions` |
| Hook output spills at 2,500 tokens | mechanism §4 | `hooks/src/output_spill.rs:12,135` | `Full hook output saved to` |

## Injected context

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| `project_doc_max_bytes` default is 32 KiB, total | SKILL outside playbook, mechanism §1 | `config/src/config_toml.rs:68` | `DEFAULT_PROJECT_DOC_MAX_BYTES` |
| AGENTS.md cut mid-file; only trace is a server-side log | SKILL outside playbook, mechanism §1 | `core/src/agents_md.rs:106-144` | `LOCAL_AGENTS_MD_FILENAME` |
| Skills catalog gets 2% of the context window | mechanism §1 | `core-skills/src/render.rs:19,24-25` | `SKILL_METADATA_CONTEXT_WINDOW_PERCENT` |
| Descriptions are shortened under that budget | mechanism §1 | `core-skills/src/render.rs:24-25` | `Skill descriptions were shortened` |
| The `ext/skills` catalog budget is capped at 4,000 tokens | mechanism §6 | `ext/skills/src/render.rs:19` | `MAX_SKILL_METADATA_TOKEN_BUDGET` |
| Ambiguous `$mention` is silently skipped | mechanism §1 | `core-skills/src/injection.rs:433-434` | `skill_count != 1` |
| Untrusted host values truncate at ~1,000 tokens | mechanism §1 | `context-fragments/src/additional_context.rs:5` | `MAX_ADDITIONAL_CONTEXT_VALUE_TOKENS` |
| Internal-context marker | mechanism §1 | `core/src/context/internal_model_context.rs:7` | `CONTEXT_START_MARKER` |
| The `never` policy announcement forbids `sandbox_permissions` | mechanism §1 | `prompts/templates/permissions/approval_policy/never.md:1` | `commands will be rejected` |
| The `on-request` announcement forbids destructive prefix rules | mechanism §1, §2 | `prompts/templates/permissions/approval_policy/on_request.md:50` | `NEVER provide a prefix_rule argument` |
| **Managed "force exact value" is an open set** | SKILL Layer 0, mechanism Layer 0 | `core/src/config/requirements.rs:29-49` | `allow_login_shell` |
| **Model catalog `tool_mode` is read first, with no local override** | SKILL Layer 0, mechanism Layer 0 | `core/src/tools/mod.rs:64-74` | `effective_tool_mode` |
| …and the shipped catalog uses it | SKILL Layer 0 | `models-manager/models.json` | `"tool_mode": "code_mode_only"` |
| Goal steering pushes back on scope shrinking | mechanism §1 | `prompts/templates/goals/continuation.md:27` | `Do not substitute a narrower` |
| Periodic timestamp reminder | mechanism §1 | `core/src/context/current_time_reminder.rs:17,36` | `current_time_reminder` |

## Results on the way back

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Exec results are framed with exit code and wall time | mechanism §4 | `core/src/tools/mod.rs:93-99` | `Wall time:` |
| Timeout prefix | mechanism §4 | `core/src/tools/mod.rs:119` | `command timed out after` |
| PostToolUse can swap visible text while retaining the original | mechanism §4 | `core/src/tools/registry.rs:670-693` | `PostToolUseFeedbackOutput` |
| Unknown tool name | SKILL triage, mechanism §2 | `core/src/tools/registry.rs:775` | `unsupported call:` |
| PreToolUse veto wording | SKILL triage, mechanism §2 | `core/src/hook_runtime.rs:212` | `Command blocked by PreToolUse hook` |
| Hooks that exit before reading stdin keep their output | mechanism §2 | `hooks/src/engine/command_runner.rs:86-87` | `ErrorKind::BrokenPipe` |
| Unsupported modalities replaced with placeholder text | mechanism §4 | `core/src/context_manager/normalize.rs:14,16` | `content omitted because you do not support` |
| A rejected image ends the turn, no silent retry | mechanism §4 | `core/src/session/turn.rs:492` | `Invalid image in your last message` |
| Orphan tool outputs dropped before each request | mechanism §4 | `core/src/context_manager/normalize.rs:147` | `remove_orphan_outputs` |

## Cross-cutting loops

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Compaction presents the agent's own past as a stranger's | mechanism §5 | `prompts/templates/compact/summary_prefix.md:1` | `Another language model started to solve this problem` |
| `<turn_aborted>` marker | SKILL inside playbook, mechanism §5 | `core/src/context/turn_aborted.rs:29` | `turn_aborted` |
| Aborted calls become synthetic outputs | mechanism §5 | `core/src/tools/parallel.rs:257` | `aborted by user after` |
| One-time WebSocket→HTTPS fallback notice | mechanism §5 | `core/src/responses_retry.rs:40` | `Falling back from WebSockets` |
| Stop hooks fail open on timeout | mechanism §5 | `hooks/src/events/stop.rs` | `should_block` |
| SessionEnd timeout 1 s, hard cap 3 s | mechanism §5 | `hooks/src/events/session_end.rs:20,23` | `SESSION_END_MAX_TIMEOUT_SEC` |
| SessionEnd is root-session only | mechanism §5 | `core/src/hook_runtime.rs:378-382` | `SessionSource::SubAgent` |
| SessionEnd `async: true` is a no-op | mechanism §5 | `hooks/src/engine/discovery.rs:480-506` | `running async SessionEnd hook synchronously` |
| Review mode forces `never` and disables web search | mechanism §5 | `core/src/tasks/review.rs:107-118` | `WebSearchMode::Disabled` |
| Headless `codex exec` defaults to `never`; AutoReview lifts it | SKILL outside playbook, mechanism §3 | `exec/src/lib.rs:425-427,606-639` | `ApprovalsReviewer::AutoReview` |

## Subsystems

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| **Multi-agent V1 is stable and default-enabled** | SKILL default surface, mechanism §6 | `features/src/lib.rs:1077-1081` | `"multi_agent"` |
| Spawn depth defaults to 1 | SKILL default surface, mechanism §6 | `core/src/config/mod.rs:269` | `agent_max_depth` |
| Built-in roles are currently inert | mechanism §6 | `core/src/agent/role.rs:359-377` | `built_in` |
| A role can carry its own sandbox and approval policy | SKILL default surface, mechanism §6 | `core/src/agent/control/spawn.rs:288-312` | `build_agent_spawn_config` |
| Code-mode feature flags are under development, default off | SKILL off-by-default table | `features/src/lib.rs:886-909` | `CodeModeOnly` |
| Code mode exposes `exec` and `wait` | SKILL Layer 0, mechanism §6 | `code-mode-protocol/src/lib.rs:45-46` | `PUBLIC_TOOL_NAME` |
| `console` is deleted from the JS global object | mechanism §6 | `code-mode/src/runtime/globals.rs:17` | `console` |
| Nested tool calls go through the same router | SKILL Layer 0, mechanism §6 | `core/src/tools/code_mode/mod.rs:293-333` | `call_nested_tool` |
| A failed nested call becomes a rejected promise | SKILL Layer 0, mechanism §6 | `code-mode/src/runtime/mod.rs:242-249` | `resolve_tool_response` |
| `CodeModeOnly` hides other tools from the menu | mechanism §6 | `core/src/tools/spec_plan.rs:242-259,434-455` | `DirectModelOnly` |
| Skills are reachable as `list` / `read` tools | SKILL default surface, mechanism §6 | `ext/skills/src/tools/list.rs:30`, `read.rs:26` | `TOOL_NAME` |
| **No general secret redaction in the exec output path** | SKILL default surface, mechanism §4 | `secrets/src/sanitizer.rs:1-22` | `redact_secrets` |
| Plugins can declare MCP servers and hooks | mechanism §6 | `plugin/src/manifest.rs:19-42` | `PluginManifestHooks` |
| Plan mode hard-blocks `update_plan` only | mechanism §6 | `core/src/tools/handlers/plan.rs:84-88` | `not allowed in Plan mode` |
| No `<collaboration_mode>` fragment in a default session | mechanism §6 | `core/tests/suite/collaboration_instructions.rs:61-99` | `no_collaboration_instructions_by_default` |
| zsh-fork backends are under development, default off | SKILL off-by-default table | `features/src/lib.rs:856-867` | `shell_zsh_fork` |
| Per-exec denial wording | SKILL triage, mechanism §2 | `shell-escalation/src/unix/escalate_client.rs:118` | `Execution denied:` |
| Memories are stable but default off | SKILL off-by-default table | `features/src/lib.rs:965-968` | `"memories"` |

---

## Empirically verified

Confirmed by running `codex-cli 0.146.0-alpha.10` on macOS, not by reading source. These are the highest-confidence rows in this file, and the commands are cheap to repeat.

`codex debug prompt-input` renders the model-visible prompt as JSON with **no model call**, which makes every injected-context claim verifiable for free.

| Claim | How it was confirmed | Result |
|---|---|---|
| `<permissions instructions>`, `<environment_context>`, `# AGENTS.md instructions` markers are real | `codex debug prompt-input` | All three present |
| The permissions announcement discloses sandbox mode, read/write scope, and network state up front | same | Confirmed — `` `sandbox_mode` is `workspace-write` … Network access is restricted `` |
| The `never` announcement text | `codex debug prompt-input -c approval_policy=never -c sandbox_mode=read-only` | Verbatim: ``Approval policy is currently never. Do not provide the `sandbox_permissions` for any reason, commands will be rejected.`` |
| The `on-request` announcement forbids destructive prefix rules | `codex debug prompt-input` (default policy) | Verbatim: `NEVER provide a prefix_rule argument for destructive commands like rm.` |
| Under `never`, the escalation instructions are removed entirely rather than reworded | compare the two dumps above | Confirmed — the whole "How to request escalation" section is absent |
| Host skill paths are aliased under metadata pressure | `codex debug prompt-input` | Confirmed — skills render as `(file: r0/<skill>/SKILL.md)` |
| Escalation is requested via `sandbox_permissions: "require_escalated"` | same | Confirmed in the on-request announcement |
| **OS-jail denials reach the model as unwrapped, verbatim command stderr** | `codex exec -s read-only -c approval_policy=never` attempting `touch /tmp/…` | Model saw exactly `touch: /tmp/codex_probe_a.txt: Operation not permitted` |
| **Policy rejections reach the model nested in a spawn-error wrapper** | same run, attempting `rm -rf` | Model saw `` exec_command failed for `/bin/zsh -c '…'`: CreateProcess { message: "Rejected(\"approval required by policy, but AskForApproval is set to Never\")" } `` |
| **The forced-rm reason does not fire for every `rm -rf`** | same run | A shell-wrapped `rm -rf` under `never` produced the generic reason, not `rm -f style commands are not permitted` |

Reproduce the exec probe with:

```
codex exec --json -s read-only -c approval_policy=never --skip-git-repo-check --ephemeral \
  "run: touch /tmp/probe_a.txt ; then run: rm -rf /tmp/probe_dir ; quote both errors verbatim, do not retry"
```

## Re-verification procedure

1. **Scope the diff.** From a codex checkout:

   ```
   git log --oneline <pinned>..HEAD -- \
     codex-rs/core codex-rs/execpolicy codex-rs/sandboxing codex-rs/linux-sandbox \
     codex-rs/windows-sandbox-rs codex-rs/hooks codex-rs/network-proxy \
     codex-rs/apply-patch codex-rs/exec codex-rs/prompts codex-rs/features
   ```

2. **Check the anchors.** For each row, `rg` the **match on** column. A hit means the claim's anchor survives; follow it to confirm the surrounding logic still says the same thing. A miss means the constant or string was renamed or removed — re-derive the claim before editing the prose, and do not assume the behavior changed just because the identifier did.

3. **Line numbers drift; identifiers usually don't.** Treat the `file:line` column as a starting point and the **match on** column as the real key. Update line numbers as you go.

4. **Update the pin** at the top of this file and the verification line at the top of `SKILL.md`.

### Known gaps in the current pass

- Roughly half of the commits between the previous pin and this one were triaged by subject line only, outside the crates listed in step 1. A zero-miss sweep would need a second pass.
- Whether `ext/skills` feeds the same agent context as the primary `core-skills` render path was not established. If it does, its capped budget and its catalog-warning behavior may apply more broadly than stated.
- The macOS and Windows equivalents of the Linux `.git` / `.agents` / `.codex` writable-root carve-out were not individually re-read.

### Traps

- **Do not trust "the file did not change in range" as evidence a claim is true.** It is evidence the claim did not *change*. The Windows degrade-vs-refuse error survived a previous review precisely this way.
- **Do not `rg` a full quoted template.** See the note at the top of this file.
