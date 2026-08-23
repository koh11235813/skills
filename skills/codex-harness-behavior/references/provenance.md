# Provenance ledger

Evidence for every load-bearing claim in `SKILL.md` and `references/mechanism.md`, so the next update is a diff against this table rather than a re-reading of the prose.

**Pinned:** codex-rs `main` @ `c9b19deb09`, 2026-08-23.

Paths are relative to `codex-rs/` in the [openai/codex](https://github.com/openai/codex) repository.

The **match on** column is what to `rg` for. It is deliberately *not* the full string as quoted in the prose: most quoted strings are `format!` templates whose placeholder names differ from the source (the docs say `unsupported call: {tool}`; the source says `format!("unsupported call: {tool_name}")`). Searching the whole template returns zero hits for claims that are perfectly correct. **Always match on the literal fragment between placeholders, or on the constant/type name.**

---

## Command classification (exec policy)

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Banned allow-prefix list has 88 entries | mechanism §2 | `core/src/exec_policy.rs:56-145` | `BANNED_PREFIX_SUGGESTIONS` |
| Forbidden prefix never spawns | SKILL triage, mechanism §2 | `core/src/exec_policy.rs:1039` | `rejected: policy forbids commands starting with` |
| Dangerous-rm heuristic forbids outright | SKILL triage, mechanism §2 | `core/src/exec_policy.rs:1069` | `rm -f style commands are not permitted` |
| …but the rm string only replaces the fallback reason when a forced-rm match is still identified at rejection time | SKILL triage, mechanism §2, §4 | `core/src/exec_policy.rs:396,1052-1062` | `derive_rejected_prompt_reason` |
| Prompt suppressed under `never` | SKILL triage, mechanism §2 | `core/src/exec_policy.rs:47-48,219` | `approval required by policy, but AskForApproval` |
| Two Granular-specific rejections exist | mechanism §4 table | `core/src/exec_policy.rs:49-52` | `Granular.sandbox_approval is false` |
| Windows-without-backend prompts (or forbids under `never`) for every unmatched command under the downgraded managed read-only profile | SKILL Windows para, mechanism §3 | `core/src/exec_policy.rs:749,759,817` | `windows_managed_fs_restrictions_without_sandbox_backend` |
| Escalation request in a forbidding mode is scripted-rejected | SKILL triage, mechanism §2 | `core/src/tools/handlers/unified_exec/exec_command.rs:292` | `you cannot ask for escalated permissions` |
| One-shot migration strips banned saved rules | mechanism §2 | `execpolicy/src/sandbox_migration.rs:85` | `strip_banned_allow_rules` |
| The known-safe safelist module is gone; only the dangerous-command classifier remains | SKILL Windows para, mechanism §2, §3 | `shell-command/src/command_safety/mod.rs:8` | `pub mod is_dangerous_command` |
| Dangerous-command classification fails closed past wrapper depth 8 | mechanism §2 | `shell-command/src/command_safety/is_dangerous_command.rs:16,27` | `MAX_DANGEROUS_COMMAND_WRAPPER_DEPTH` |
| `approval_policy = "untrusted"` is a hard config error | SKILL mode-matrix note, SKILL outside playbook, mechanism §2 | `core/src/config/mod.rs:199-200,3606` | `UnsupportedUntrustedApprovalPolicyError` |
| App-server config writes reject it separately | mechanism §2 | `app-server/src/config_manager_service.rs:742` | `is no longer supported; remove this setting` |
| The CLI approval enum no longer spells `untrusted` | SKILL mode-matrix note | `utils/cli/src/approval_mode_cli_arg.rs:9-16` | `enum ApprovalModeCliArg` |
| An untrusted project resolves to `UnlessTrusted` by default | SKILL mode-matrix note, mechanism §2 | `core/src/config/mod.rs:3615-3622` | `active_project.is_untrusted()` |
| An app-server `thread/start` approval policy becomes a config override and bypasses the check | SKILL mode-matrix note, mechanism §2 | `app-server/src/request_processors/thread_processor.rs:1549,1556,1570-1571`; `core/src/config/mod.rs:3207` | `fn build_thread_config_overrides`; `approval_policy_override` |
| The v2 wire enum still exposes `"untrusted"` | mechanism §2 | `app-server-protocol/src/protocol/v2/shared.rs:174-177` | `enum AskForApproval` |
| Managed requirements pin the first allowed policy as the required default | mechanism §2 | `config/src/config_requirements.rs:917,1659-1665` | `allowed_approval_policies` |
| Under `unless-trusted` every unmatched command prompts | SKILL mode-matrix note, mechanism §2 | `core/src/exec_policy.rs:774-779` | `Projects marked untrusted require approval` |
| Unmatched-command fallback = policy × sandbox kind × sandbox-override request | mechanism §2 | `core/src/exec_policy.rs:769-812` | `requests_sandbox_override()` |
| The Windows no-backend guard needs a codex-managed, restricted, non-full-write profile | SKILL Windows para, mechanism §3 | `core/src/exec_policy.rs:749-751,817-825` | `profile_has_managed_filesystem_restrictions` |
| An explicit exec-policy allow still bypasses the sandbox | SKILL Windows para, mechanism §3 | `core/src/exec_policy.rs:419-422` | `bypass_sandbox` |
| Unquoted shell metacharacters abort literal parsing | SKILL inside playbook, mechanism §2 | `shell-command/src/bash.rs:243,260-274` | `is_literal_word_or_number` |
| …and the whole wrapper then becomes the policy subject | SKILL inside playbook, mechanism §2 | `core/src/exec_policy.rs:831-841` | `fn commands_for_exec_policy` |
| Cyber models / managed `ignore_rules` strip every Allow prefix rule | SKILL Layer 0, mechanism §2 | `core/src/session/turn_context.rs:246-261`; `core/src/exec_policy/model_policy.rs:11,27-52` | `IgnoreForCyberModel` |
| Two shipped catalog slugs carry `model_specialty: "cyber"` | SKILL Layer 0, mechanism §2 | `models-manager/models.json:408,526` | `"model_specialty": "cyber"` |
| …and no reusable prefix-rule amendment is proposed in that mode | SKILL Layer 0, mechanism §2 | `core/src/exec_policy.rs:340,362,434` | `auto_amendment_allowed` |
| Environments carry a restrictive-only exec-policy overlay | mechanism §2 | `core/src/session/environment.rs:78`; `core/src/exec_policy/model_policy.rs:15-25` | `environment command policy cannot contain allow rules` |

## Approval gate

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Approval cache key is 7 fields (adds executable, tty) | SKILL inside playbook, mechanism §2 | `core/src/tools/runtimes/unified_exec.rs:89-97` | `UnifiedExecApprovalKey` |
| …and the lookup pairs that key with the selected environment's exec-policy fingerprint | SKILL inside playbook, mechanism §2 | `core/src/tools/approvals.rs:640-650` | `RequirementsExecPolicy::fingerprint` |
| Only `ApprovedForSession` decisions are cached; denials are not | SKILL triage, mechanism §2 | `core/src/tools/sandboxing.rs:88-97` | `ReviewDecision::ApprovedForSession` |
| Command is canonicalized before keying, while the executable field keeps the raw first token | SKILL inside playbook, mechanism §2 | `core/src/command_canonicalization.rs:5,14-36`; `core/src/tools/approvals.rs:207-215` | `__codex_shell_script__`; `executable: command.first().cloned()` |
| Denial reasons are propagated; the hook default is "PermissionRequest hook denied approval" and "rejected by configuration" is network-amendment-deny only | SKILL triage, mechanism §4 | `core/src/tools/approvals.rs:420`; `hooks/src/engine/output_parser.rs:413` | `PermissionRequest hook denied approval`; `rejected by configuration` |
| Guardian denial wording | SKILL triage, mechanism §4 | `core/src/guardian/review.rs:733` | `rejected due to unacceptable risk` |
| Human denial normalized — and *only* the exact string `rejected by user` is | SKILL triage, mechanism §4 | `core/src/tools/events.rs:441-448` | `exec command rejected by user` |
| Deserialization/client/transport failures keep the reason `approval request failed` | SKILL triage, mechanism §2 | `app-server/src/bespoke_event_handling.rs:1954,2042` | `approval request failed` |
| Abort tears down the whole turn | mechanism §2 | `core/src/session/handlers.rs:196-208` | `ReviewDecision::Abort` |
| MCP denial never contacts the server | SKILL triage, mechanism §4 | `core/src/mcp_tool_call.rs:1894` | `user rejected MCP tool call` |
| Escalation and retries force synchronous Guardian review, skipping extension reviewers | mechanism §2, §3 | `core/src/guardian/review.rs:325,341` | `requires_synchronous_review` |
| Guardian denial circuit breaker: 3 consecutive / 10-in-50, and 1/1 for a cyber-specialty model **only** — an `auto_review.ignore_rules` slug does not select it | SKILL triage, mechanism §2 | `core/src/guardian/mod.rs:55-59,163-183`; `core/src/guardian/review.rs:252-257` | `MAX_CONSECUTIVE_CYBER_GUARDIAN_DENIALS_PER_TURN`; `MODEL_SPECIALTY_CYBER` |
| `guardian_approval` is stable and default-enabled; guardian routing additionally requires `approvals_reviewer` to be `auto_review` (default `user`) and the policy to be `on-request` or granular | SKILL off-by-default table | `features/src/lib.rs:1386-1391`; `protocol/src/config_types.rs:183-189`; `core/src/guardian/review.rs:201-209` | `key: "guardian_approval"`; `routes_approval_policy_to_guardian` |
| A stored grant preapproves only an exactly-matching request | mechanism §2 | `core/src/tools/handlers/mod.rs:309` | `fn preapproved_permission_profile` |
| Strict auto-review can be enabled mid-turn | mechanism §2 | `core/src/state/turn.rs:255`; `core/src/session/mod.rs:2850` | `enable_strict_auto_review` |
| Managed requirements can force AutoReview by model slug | mechanism §2 | `config/src/requirements_layers/models.rs:22,49` | `required_on_models` |
| A network request disconnecting during approval cancels the *owning execution*, and only when one is attributed | SKILL triage, mechanism §3, §4 | `core/src/tools/network_approval.rs:354,660-676` | `before approval could complete`; `execution_id: owner_call` |
| …but the disconnect never cancels the approval reviewer or changes its decision | SKILL triage, mechanism §3 | `network-proxy/src/request_disconnect.rs:8-11` | `struct NetworkRequestDisconnect` |
| Codex delegates are refused unless approval policy is `never` | mechanism §5 | `core/src/codex_delegate.rs:65` | `Codex delegates require approval policy` |

## OS sandboxing

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| **Windows downgrades workspace-write to read-only** | SKILL mode matrix, mechanism §3 | `core/src/config/permissions.rs:48-59` | `default_builtin_permission_profile_name` |
| …and a test asserts exactly that | — | `cli/src/debug_sandbox.rs:938` | `downgrades to read-only when the Windows sandbox is disabled` |
| Windows sandbox backend ships disabled | SKILL mode matrix, mechanism §3 | `features/src/lib.rs:1076-1080` | `experimental_windows_sandbox` |
| `CODEX_SANDBOX=seatbelt` is macOS-only | SKILL inside playbook, mechanism §3 | `core/src/sandboxing/mod.rs:178-180` | `CODEX_SANDBOX_ENV_VAR` |
| `CODEX_SANDBOX_NETWORK_DISABLED` on every platform | SKILL inside playbook, mechanism §3 | `core/src/spawn.rs:21,86-88` | `CODEX_SANDBOX_NETWORK_DISABLED` |
| Protected workspace metadata is deleted and forces exit 1 | mechanism §3 | `linux-sandbox/src/linux_run_main.rs:1236` | `sandbox blocked creation of protected workspace metadata path` |
| Seatbelt profile is deny-by-default | mechanism §3 | `sandboxing/src/seatbelt_base_policy.sbpl:8` | `(deny default)` |
| Linux network syscalls return EPERM via seccomp | mechanism §3 | `linux-sandbox/src/landlock.rs:250-253` | `SeccompAction::Errno` |
| Denial detection is 7 keywords + exit codes + SIGSYS | SKILL triage, mechanism §3 | `sandboxing/src/denial.rs:52-59` | `landlock` |
| The single retry-unsandboxed gate | mechanism §3 | `core/src/tools/orchestrator.rs:552` | `retry without sandbox` |
| `UnlessTrusted` is the only policy the default `wants_no_sandbox_approval` accepts for every tool; `Granular` needs its `sandbox_approval` flag, and the apply_patch runtime overrides the default to accept `OnRequest` too | SKILL mode matrix, mechanism §2 | `core/src/tools/sandboxing.rs:329-337`; `core/src/tools/runtimes/apply_patch.rs:132-139`; `core/src/tools/orchestrator.rs:369,486` | `fn wants_no_sandbox_approval` |
| …and a denied-read filesystem policy blocks the unsandboxed attempt entirely | SKILL mode matrix, mechanism §2 | `core/src/tools/sandboxing.rs:275-279`; `core/src/tools/orchestrator.rs:232,391` | `fn unsandboxed_execution_allowed` |
| Blocked host wording | mechanism §3 | `core/src/tools/orchestrator.rs:404` | `is blocked by policy` |
| `LD_*` / `DYLD_*` stripped | mechanism §3 | `process-hardening/src/lib.rs:60,79,99` | `remove_env_vars_with_prefix` |
| Explicit loopback allowlist entries now connect | mechanism §3 | `network-proxy/src/connect_policy.rs:87,102,124` | `allows_non_public_target` |
| Missing protected paths are materialized on Linux as synthetic empty read-only mounts; macOS emits deny regexes covering paths that do not exist | mechanism §3 | `linux-sandbox/src/bwrap.rs:1044,1077`; `sandboxing/src/seatbelt.rs:644` | `append_missing_read_only_subpath_args` |
| Windows kills process trees via job objects | mechanism §3, §5 | `utils/pty/src/win/job.rs:34` | `JobObject` |
| `.git`/`.agents`/`.codex` carve-out is one shared list rendered by three backends | mechanism §3 | `protocol/src/permissions.rs:29,37,1238` | `PROTECTED_METADATA_PATH_NAMES` |
| …and Windows renders it as deny ACEs, dropping any path that does not yet exist | mechanism §3 | `windows-sandbox-rs/src/allow.rs:27-31,36-37` | `add_deny_path` |
| macOS denies unlink of writable dir roots and protected ancestors | mechanism §3 | `sandboxing/src/seatbelt.rs:508,644` | `deny file-write-unlink` |
| macOS refuses *nested* symlinked writable-root components, normalizing top-level aliases such as `/tmp -> /private/tmp` instead | SKILL triage, mechanism §3 | `sandboxing/src/seatbelt.rs:396-405,441-450` | `symlinked writable roots are not supported`; `fn nested_symlink_component` |
| macOS preferences policy is appended only under full-disk read | mechanism §3 | `sandboxing/src/seatbelt.rs:23,992` | `MACOS_SEATBELT_PREFERENCES_POLICY` |
| Linux drops all capabilities | mechanism §3 | `linux-sandbox/src/bwrap.rs:294,352` | `--cap-drop` |
| Linux sandbox runs as PID 1 and reaps orphans | mechanism §3 | `linux-sandbox/src/launcher.rs:39,197` | `--as-pid-1` |
| Linux materializes synthetic empty protected dirs | mechanism §3 | `linux-sandbox/src/bwrap.rs:1044,1077` | `append_missing_read_only_subpath_args` |
| Project-root discovery requires a `HEAD` file inside `.git` | mechanism §3 | `config/src/loader/mod.rs:1344-1348` | `join("HEAD")` |

## Limits and truncation

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Exec timeout 10 s, exit forced to 124 | mechanism §3 | `core/src/exec.rs:61,68,766` | `DEFAULT_EXEC_COMMAND_TIMEOUT_MS` |
| stdout, stderr, and aggregate share one 1 MiB constant | mechanism §3 | `utils/pty/src/lib.rs:12`, `core/src/exec.rs:79,264-268,732` | `DEFAULT_OUTPUT_BYTES_CAP` |
| Unified-exec wait constants | mechanism §3 | `core/src/unified_exec/mod.rs:68,71,72` | `MIN_EMPTY_YIELD_TIME_MS` |
| Empty polls clamp to `[5 s, configured max]`; non-empty capped at 30 s | mechanism §3 | `core/src/unified_exec/process_manager.rs:824-829` | `clamp(MIN_EMPTY_YIELD_TIME_MS` |
| Tool-schema compaction is 4 progressive passes over a 5,000-byte threshold | SKILL default surface, mechanism §1 | `tools/src/json_schema.rs:222,240-245` | `prune_schema_compositions` |
| Hook output spills at 2,500 tokens | mechanism §4 | `hooks/src/output_spill.rs:12,127` | `Full hook output saved to` |

## Injected context

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| `project_doc_max_bytes` default is 32 KiB, total | SKILL outside playbook, mechanism §1 | `config/src/config_toml.rs:73` | `DEFAULT_PROJECT_DOC_MAX_BYTES` |
| AGENTS.md cut mid-file; only trace is a server-side log | SKILL outside playbook, mechanism §1 | `core/src/agents_md.rs:44,166-179` | `LOCAL_AGENTS_MD_FILENAME` |
| Skills catalog gets 2% of the context window | mechanism §1, §6 | `ext/skills/src/render.rs:20,127-153` | `SKILL_METADATA_CONTEXT_WINDOW_PERCENT` |
| Descriptions are shortened under that budget | mechanism §1, §6 | `ext/skills/src/render.rs:25` | `Skill descriptions were shortened` |
| Catalog budget = configured `max_context_tokens` capped at 10,000 tokens, else 2% of window, else 8,000 characters | mechanism §6 | `ext/skills/src/render.rs:17-19,127-153` | `MAX_CONFIGURED_SKILL_METADATA_TOKEN_BUDGET` |
| Ambiguous `$mention` is silently skipped | mechanism §1 | `skills/src/selection.rs:188` | `skill_count != 1` |
| Untrusted host values truncate at ~1,000 tokens | mechanism §1 | `context-fragments/src/additional_context.rs:6` | `MAX_ADDITIONAL_CONTEXT_VALUE_TOKENS` |
| Internal-context marker | mechanism §1 | `core/src/context/internal_model_context.rs:8` | `CONTEXT_START_MARKER` |
| The `never` policy announcement forbids `sandbox_permissions` | mechanism §1 | `prompts/templates/permissions/approval_policy/never.md:1` | `commands will be rejected` |
| The `on-request` announcement forbids destructive prefix rules | mechanism §1, §2 | `prompts/templates/permissions/approval_policy/on_request.md:50` | `NEVER provide a prefix_rule argument` |
| **Managed "force exact value" is an open set** | SKILL Layer 0, mechanism Layer 0 | `core/src/config/requirements.rs:29-49` | `allow_login_shell` |
| **Model catalog `tool_mode` is read first, with no local override** | SKILL Layer 0, mechanism Layer 0 | `core/src/tools/mod.rs:67-77,79` | `effective_tool_mode` |
| …and the shipped catalog uses it | SKILL Layer 0, mechanism Layer 0 | `models-manager/models.json:20,151,277,399,517,1082` | `"tool_mode": "code_mode_only"` |
| Goal steering pushes back on scope shrinking | mechanism §1 | `prompts/templates/goals/continuation.md:27` | `Do not substitute a narrower` |
| Periodic timestamp reminder | mechanism §1 | `core/src/context/current_time_reminder.rs:28-30,35-37` | `<current_time_reminder>` |
| A saved prefix rule or network rule is echoed back as a context fragment | mechanism §1, §2 | `core/src/context/approved_command_prefix_saved.rs:22`; `core/src/context/mod.rs:3,25,43-44,75` | `approved_command_prefix_saved`; `NetworkRuleSaved` |
| Untrusted projects load no project AGENTS.md at all | SKILL inside playbook, mechanism §1 | `core/src/agents_md.rs:64-66` | `active_project.is_untrusted()` |
| Sandboxed AGENTS.md read failure returns an error rather than degrading | mechanism §1 | `core/src/agents_md.rs:120` | `failed to load AGENTS.md instructions for environment` |
| `project_doc_max_bytes` is one pool across all environments | SKILL outside playbook, mechanism §1 | `core/src/agents_md.rs:68` | `let mut remaining = config.project_doc_max_bytes` |
| Skills budget warnings go to the client, not into context | SKILL default surface, mechanism §6 | `ext/skills/src/render.rs:93`; `ext/skills/src/extension.rs:617-623` | `fn warning_message` |
| Skill locators are aliased to `r0`/`r1` unannounced | mechanism §6 | `ext/skills/src/render.rs:522,1028` | `build_aliased_catalog` |
| Combined catalogs share one budget | mechanism §6 | `ext/skills/src/render.rs:544` | `render_combined_available_skills` |

## Results on the way back

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Exec results are framed with exit code and wall time | mechanism §4 | `core/src/tools/mod.rs:109` | `Wall time:` |
| Timeout prefix | mechanism §4 | `core/src/tools/mod.rs:134` | `command timed out after` |
| PostToolUse can swap visible text while retaining the original | mechanism §4 | `core/src/tools/registry.rs:212-217,730` | `PostToolUseFeedbackOutput` |
| Unknown tool name | SKILL triage, mechanism §2 | `core/src/tools/registry.rs:818` | `unsupported call:` |
| PreToolUse veto wording forks on whether the call carries a command string | SKILL triage, mechanism §2 | `core/src/hook_runtime.rs:223,227` | `blocked by PreToolUse hook` |
| Hooks that exit before reading stdin keep their output | mechanism §2 | `hooks/src/engine/command_runner.rs:269` | `ErrorKind::BrokenPipe` |
| Unsupported modalities replaced with placeholder text | mechanism §4 | `core/src/context_manager/normalize.rs:15,17` | `content omitted because you do not support` |
| A rejected image ends the turn, no silent retry | mechanism §4 | `core/src/session/turn.rs:567` | `Invalid image in your last message` |
| Orphan tool outputs dropped before each request | mechanism §4 | `core/src/context_manager/normalize.rs:155` | `remove_orphan_outputs` |

## Tool registry and session plumbing

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Reserved names and duplicate external tools are dropped with only a local log | mechanism §2 | `core/src/tools/registry.rs:350` | `skipping external tool with reserved name` |
| Collisions are fatal only under an opt-in flag | mechanism §2 | `core/src/tools/spec_plan.rs:379` | `error_on_tool_collisions` |
| Shell commands receive `CODEX_SESSION_ID` | mechanism §2 | `core/src/exec_env.rs:13,40` | `CODEX_SESSION_ID_ENV_VAR` |
| A retryable `ConnectionFailed` on a **sampling** request retries without a count limit — non-internal, non-Bedrock only; the feature is Stable/default-on | SKILL outside playbook, mechanism §5 | `features/src/lib.rs:1100-1105`; `core/src/responses_retry.rs:58-82` | `unbounded_connection_retries`; `is_amazon_bedrock` |
| …with backoff doubling from 5 s to a 60 s cap, and a server-side warning alongside the frontend notice | SKILL outside playbook, mechanism §5 | `core/src/responses_retry.rs:17-18,67-80` | `MAX_CONNECTION_RETRY_DELAY` |
| …emitting only a reconnect notice | mechanism §5 | `core/src/responses_retry.rs:74` | `waiting for network` |
| Remote compaction V2 can retain client-authored developer messages across the boundary | mechanism §5 | `core/src/compact_remote_v2.rs:459,475-477`; `features/src/lib.rs:1548-1553` | `retain_client_developer_messages`; `is_client_authored_developer_message` |

## Cross-cutting loops

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| Compaction presents the agent's own past as a stranger's | mechanism §5 | `prompts/templates/compact/summary_prefix.md:1` | `Another language model started to solve this problem` |
| `<turn_aborted>` marker | SKILL inside playbook, mechanism §5 | `core/src/context/turn_aborted.rs:34` | `turn_aborted` |
| Aborted calls become synthetic outputs | mechanism §5 | `core/src/tools/parallel.rs:258` | `aborted by user after` |
| One-time WebSocket→HTTPS fallback notice | mechanism §5 | `core/src/responses_retry.rs:94` | `Falling back from WebSockets` |
| Stop hooks fail open on timeout | mechanism §5 | `hooks/src/events/stop.rs` | `should_block` |
| SessionEnd timeout 1 s, hard cap 3 s | mechanism §5 | `hooks/src/events/session_end.rs:20,23` | `SESSION_END_MAX_TIMEOUT_SEC` |
| SessionEnd is root-session only | mechanism §5 | `core/src/hook_runtime.rs:409-411` | `SessionSource::SubAgent` |
| SessionEnd `async: true` is a no-op | mechanism §5 | `hooks/src/engine/discovery.rs:532` | `running async SessionEnd hook synchronously` |
| Review mode forces `never` and disables web search | mechanism §5 | `core/src/tasks/review.rs:109,119` | `WebSearchMode::Disabled` |
| Headless `codex exec` defaults to `never`; AutoReview lifts it | SKILL outside playbook, mechanism §3 | `exec/src/lib.rs:413,599-614` | `ApprovalsReviewer::AutoReview` |

## Subsystems

| Claim | Where it ships | Source | Match on |
|---|---|---|---|
| **Multi-agent V1 is stable and default-enabled**, and V2 (`multi_agent_v2`) is Stable but default **off** | SKILL default surface, mechanism §6 | `features/src/lib.rs:1122-1133` | `key: "multi_agent"`; `key: "multi_agent_v2"` |
| The resolved version comes from the V2 feature, else the model catalog, else the `multi_agent` feature | SKILL default surface, mechanism §6 | `core/src/config/mod.rs:1507-1535` | `fn multi_agent_version_for_model` |
| V2 replaces `send_input`/`resume_agent`/`close_agent` with `send_message`, `followup_task`, `interrupt_agent`, `list_agents`; `wait_agent` is conditional | SKILL default surface, mechanism §6 | `core/src/tools/spec_plan.rs:1118-1201` | `SendMessageHandlerV2`; `wait_agent_enabled` |
| V1's tools register `Deferred` on a search-capable model | mechanism §6 | `core/src/tools/spec_plan.rs:578-580,1178-1182` | `fn search_tool_enabled` |
| Spawn depth defaults to 1 | SKILL default surface, mechanism §6 | `core/src/config/mod.rs:235,3761-3765` | `agent_max_depth` |
| Built-in roles are currently inert | mechanism §6 | `core/src/agent/role.rs:351-377` | `built_in` |
| A role's override set is closed, and its `features` field honors only a *disable* of six capability features, keyed by `shell_tool`, `apps`, `personality`, `plugins`, `memories`, `request_permissions_tool`, plus explicitly selected skills | SKILL default surface, mechanism §6 | `core/src/agent/role.rs:37-48,91-110`; `features/src/lib.rs:837,993,1053,1147,1219,1465`; `features/src/legacy.rs:25-26` | `struct AgentRoleOverrides`; `Feature::RequestPermissionsTool`; `fn feature_for_key` |
| Authority is not inherited but *reapplied*: spawning copies the live parent turn's approval policy, approvals reviewer, cwd and permission-profile snapshot | SKILL default surface, mechanism §6 | `core/src/tools/handlers/multi_agents_common.rs:229-259` | `fn apply_spawn_agent_runtime_overrides` |
| …while model, provider, reasoning settings and developer instructions are set from the spawn path and may differ | SKILL default surface, mechanism §6 | `core/src/tools/handlers/multi_agents_common.rs:194-215` | `fn build_agent_shared_config` |
| …and a regression test asserts it | mechanism §6 | `core/src/agent/role_tests.rs:394` | `apply_role_cannot_expand_parent_authority` |
| Code-mode feature flags are under development, default off | SKILL off-by-default table | `features/src/lib.rs:908-937` | `CodeModeOnly` |
| Code mode exposes `exec` and `wait` | SKILL Layer 0, mechanism §6 | `code-mode-protocol/src/lib.rs:50-51` | `PUBLIC_TOOL_NAME` |
| `console` is deleted from the JS global object | mechanism §6 | `code-mode-runtime/src/runtime/globals.rs:17` | `delete_global(scope, global, "console")` |
| Nested tool calls go through the same router | SKILL Layer 0, mechanism §6 | `core/src/tools/code_mode/mod.rs:293-333` | `call_nested_tool` |
| A failed nested call becomes a rejected promise | SKILL Layer 0, mechanism §6 | `code-mode-runtime/src/runtime/mod.rs:236,244`, definition `code-mode-runtime/src/runtime/module_loader.rs:66` | `resolve_tool_response` |
| `CodeModeOnly` hides other tools from the menu | mechanism §6 | `core/src/tools/spec_plan.rs:231-243,464-479` | `DirectModelOnly` |
| Skills are reachable as `list` / `read` tools | SKILL default surface, mechanism §6 | `ext/skills/src/tools/list.rs:30`, `read.rs:28` | `TOOL_NAME` |
| **No general secret redaction in the exec output path** | SKILL default surface, mechanism §4 | `secrets/src/sanitizer.rs:1-22` | `redact_secrets` |
| Plugins can declare MCP servers and hooks | mechanism §6 | `plugin/src/manifest.rs:19-42` | `PluginManifestHooks` |
| Plan mode hard-blocks `update_plan` only | mechanism §6 | `core/src/tools/handlers/plan.rs:84-88` | `not allowed in Plan mode` |
| No `<collaboration_mode>` fragment in a default session | mechanism §6 | `core/tests/suite/collaboration_instructions.rs:117-151` | `no_collaboration_instructions_by_default` |
| zsh-fork backends are under development, default off | SKILL off-by-default table | `features/src/lib.rs:860-865` | `shell_zsh_fork` |
| Per-exec denial wording | SKILL triage, mechanism §2 | `shell-escalation/src/unix/escalate_client.rs:118` | `Execution denied:` |
| Memories are stable but default off | SKILL off-by-default table | `features/src/lib.rs:992-997` | `"memories"` |
| The shell surface is exactly `exec_command` + `write_stdin` | mechanism §2 | `core/src/tools/spec_plan.rs:958,977,985` | `fn add_shell_tools` |
| …and is conditional on four gates | mechanism §2 | `core/src/tools/spec_plan.rs:962-969` | `Feature::UnifiedExec` |
| `shell_tool` and `unified_exec` are Stable/default-enabled | mechanism §2 | `features/src/lib.rs:836-841,854-859` | `key: "unified_exec"` |
| `unified_exec_zsh_fork` is `Removed`/default-true **but still a live gate**: zsh-fork mode ANDs `ShellTool`, `UnifiedExec`, `ShellZshFork` and `UnifiedExecZshFork` | SKILL off-by-default table, mechanism §3 | `tools/src/tool_config.rs:41-75`; `features/src/lib.rs:866-871` | `fn for_session`; `UnifiedExecShellMode` |
| …and a regression test asserts that disabling either zsh-fork flag forces Direct mode | mechanism §3 | `tools/src/tool_config_tests.rs:25,43-64` | `unified_exec_shell_mode_respects_feature_and_policy_gates` |
| The `shell` argument is resolved to a shell *type*, not launched as a path | mechanism §2 | `core/src/tools/handlers/unified_exec.rs:113-124`; `shell-command/src/shell_detect.rs:250-264` | `get_shell_by_model_provided_path` |
| Local zsh-fork rejects an explicit `shell` | mechanism §2 | `core/src/tools/handlers/unified_exec.rs:125-129` | `is not supported for local zsh-fork exec` |
| `shell_command` survives as a legacy catalog alias for unified exec | mechanism §2 | `protocol/src/openai_models.rs:300` | `alias = "shell_command"` |
| App-server `thread/shellCommand` runs unsandboxed with full access | SKILL outside playbook, mechanism §2 | `app-server-protocol/src/protocol/common.rs:653`; `app-server-protocol/src/protocol/v2/thread.rs:1122-1128` | `runs unsandboxed with full` |
| Code mode runs in a separate host process | mechanism §6 | `code-mode/src/remote_session.rs:39,48,183` | `OwnedCodeModeHost` |
| Guardian review injects a bounded root-conversation authorization block | mechanism §6 | `core/src/guardian/prompt.rs:222` | `ROOT CONVERSATION START` |
| `wait_agent` clamps a too-short timeout | mechanism §6 | `core/src/tools/handlers/multi_agents_v2/wait.rs:148` | `was clamped to the minimum of` |
| apply_patch refuses duplicate resolved paths | SKILL triage, mechanism §2 | `apply-patch/src/invocation.rs:237` | `multiple operations target` |
| apply_patch disables symlink traversal when the sandbox is bypassed | mechanism §2 | `core/src/tools/runtimes/apply_patch.rs:183` | `follow_symlinks` |
| Catalog supplies collaboration-mode text, `model_specialty`, and a per-model tool allowlist | SKILL Layer 0, mechanism Layer 0 | `protocol/src/openai_models.rs:446,466,535`; `core/src/tools/spec_plan.rs:1043` | `experimental_supported_tools` |
| Managed requirements inject `<managed_developer_instructions>` as a separate developer message, replacing or removing the prior block | SKILL Layer 0 | `core/src/context/world_state/managed_developer_instructions.rs:14-16,32-45`; `core/src/session/mod.rs:3737-3743` | `REPLACEMENT_NOTICE`; `managed_developer_instructions` |
| …and a rendered block over 10,000 estimated tokens is rejected at config load | SKILL Layer 0 | `core/src/context/world_state/managed_developer_instructions.rs:13,67-76` | `MAX_MANAGED_DEVELOPER_INSTRUCTIONS_TOKENS` |
| `history.*` / `notes.*` need `use_history_notes_extension`, an OpenAI provider, and Codex-backend auth | SKILL off-by-default table, mechanism §6 | `ext/history-notes/src/extension.rs:33-40` | `use_history_notes_extension` |
| …and register direct-model-only; history is bounded/read-only/eventually consistent, notes are virtual/writable/strongly consistent | SKILL off-by-default table, mechanism §6 | `ext/history-notes/src/tools.rs:25-38,376` | `NOTES_DESCRIPTION`; `MAX_HISTORY_WINDOWS` |
| An attached environment independently constrains MCP authority; pending/failed attachments expose no environment-owned servers | mechanism §6 | `core/src/mcp.rs:272-300` (call site); `codex-mcp/src/catalog.rs:337` (definition) | `build_with_environment_authority` |
| …and a restricted attachment disables non-matching servers and empty-policy plugin registrations | mechanism §6 | `codex-mcp/src/catalog.rs:340-378` | `McpEnvironmentAuthority::Restricted` |
| `send_user_message_async` is catalog-gated and root-session-only | SKILL default surface, mechanism Layer 0 | `core/src/tools/spec_plan.rs:1040-1048` | `SendUserMessageAsyncHandler`; `is_non_root_agent` |
| …and it returns immediately while the turn continues | SKILL default surface | `core/src/tools/handlers/send_user_message_async.rs:44-47,81-95` | `"accepted":true` |
| Quoting a glob preserves it as a literal argv token rather than expanding it | SKILL inside playbook | `shell-command/src/bash.rs:451-470` | `preserves_quoted_literals` |

---

## Empirically verified

Confirmed by running the CLI on macOS, not by reading source. These are the highest-confidence rows in this file, and the commands are cheap to repeat. The `codex debug prompt-input` rows were re-run at this pin on `codex-cli 0.150.0-alpha.6` (checkout tag `rust-v0.150.0-alpha.7`): the marker names and the `never` and `on-request` announcement text are unchanged. The three `codex exec` probe rows were **not** re-run this pass — they are carried over from `codex-cli 0.146.0-alpha.10` at the previous pin.

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
| **`approval_policy = "untrusted"` is a startup error, not a mode** | `codex debug prompt-input -c approval_policy=untrusted` | Verbatim: `Error: approval_policy = "untrusted" is no longer supported; remove this setting` |
| **OS-jail denials reach the model as unwrapped, verbatim command stderr** | `codex exec -s read-only -c approval_policy=never` attempting `touch /tmp/…` — carried over, not re-run | Model saw exactly `touch: /tmp/codex_probe_a.txt: Operation not permitted` |
| **Policy rejections reach the model nested in a spawn-error wrapper** | same run — carried over, not re-run | Model saw `` exec_command failed for `/bin/zsh -c '…'`: CreateProcess { message: "Rejected(\"approval required by policy, but AskForApproval is set to Never\")" } `` |
| **The forced-rm reason does not fire for every `rm -rf`** | same run — carried over, not re-run | A shell-wrapped `rm -rf` under `never` produced the generic reason, not `rm -f style commands are not permitted` |

Reproduce the exec probe with:

```
codex exec --json -s read-only -c approval_policy=never --skip-git-repo-check --ephemeral \
  "run: touch /tmp/probe_a.txt ; then run: rm -rf /tmp/probe_dir ; quote both errors verbatim, do not retry"
```

## Re-verification procedure

1. **Scope the diff.** From a codex checkout. This is the union of every directory cited in the tables above — the previous pass listed only eleven of them, and every stale claim it missed sat in one of the nineteen it did not walk:

   ```
   git log --oneline <pinned>..HEAD -- \
     codex-rs/app-server codex-rs/app-server-protocol codex-rs/apply-patch codex-rs/cli \
     codex-rs/code-mode codex-rs/code-mode-protocol codex-rs/code-mode-runtime \
     codex-rs/codex-mcp \
     codex-rs/config codex-rs/context-fragments codex-rs/core codex-rs/exec \
     codex-rs/execpolicy codex-rs/ext codex-rs/features codex-rs/hooks \
     codex-rs/linux-sandbox codex-rs/models-manager codex-rs/network-proxy \
     codex-rs/plugin codex-rs/process-hardening codex-rs/prompts codex-rs/protocol \
     codex-rs/sandboxing codex-rs/secrets codex-rs/shell-command codex-rs/shell-escalation \
     codex-rs/skills codex-rs/tools codex-rs/utils codex-rs/windows-sandbox-rs
   ```

   Regenerate this list from the **Source** column whenever rows are added, rather than editing it by hand.

2. **Check the anchors.** For each row, `rg` the **match on** column. A hit means the claim's anchor survives; follow it to confirm the surrounding logic still says the same thing. A miss means the constant or string was renamed or removed — re-derive the claim before editing the prose, and do not assume the behavior changed just because the identifier did.

3. **Line numbers drift; identifiers usually don't.** Treat the `file:line` column as a starting point and the **match on** column as the real key. Update line numbers as you go.

4. **Update the pin** at the top of this file and the verification line at the top of `SKILL.md`.

### Known gaps in the current pass

Both gaps the previous pass left open are closed. `codex-rs/core-skills` no longer exists — `ext/skills` is the only skills render path, so its budget, its aliasing and its catalog-warning behavior are the whole story rather than one of two. The `.git` / `.agents` / `.codex` carve-out is one shared list enforced on all three platforms: Linux materializes a missing protected path as a synthetic empty read-only mount, macOS emits deny regexes whether or not the path exists, and Windows renders it as deny ACEs — but only when the off-by-default sandbox backend runs, and only for paths that already exist, so a missing `.codex` gets no Windows deny ACE at all.

What this pass did not cover:

- The exec-policy, approval-gate, sandboxing and subsystem clusters got an anchor-by-anchor re-read at this pin. Even inside step 1's list the walk was anchor-scoped rather than crate-wide: `app-server` was read only at the two files cited, `models-manager` only at `models.json`. `tui` and `login` are cited nowhere in this table and were triaged by subject line only; `codex-mcp` and `ext/history-notes` were read only at the files cited.
- The AGENTS.md sandboxed-read hard-fail (`core/src/agents_md.rs:120`) was confirmed at the error arm; its caller was not traced. The string is recorded; **the user- or model-visible surface it eventually produces is unknown.** Do not promote it to a triage-table row until someone traces `load_project_instructions`'s callers.
- `unified_exec_zsh_fork` sits at `Stage::Removed` with `default_enabled: true` **and is still a live gate**: `UnifiedExecShellMode::for_session` ANDs it with `ShellTool`, `UnifiedExec` and `ShellZshFork`, and `tool_config_tests.rs` asserts that disabling either zsh-fork flag forces Direct mode. A previous pass read the feature spec alone and wrongly concluded it had stopped gating. What is still untraced is whether any other consumer reads the flag independently of `for_session`.
- Code mode's host-process resolution and its missing-host fallback were not read. The prose says only that a separate host process exists.
- `multi_agent_v2` (Stable, default off) exists alongside the default-enabled `multi_agent`, and both prose files now name the version-resolution order and V2's tool set. Untraced: V2's own handlers beyond their registration, and what `multi_agent_v2.non_code_mode_only` and `hide_spawn_agent_metadata` change for the model.
- Guardian V2 config surface, PSP routing, the Bedrock provider and the gRPC/WebSocket transport series were reviewed and rejected as not model-visible. Recorded so the next pass does not re-litigate them.

### Traps

- **Do not trust "the file did not change in range" as evidence a claim is true.** It is evidence the claim did not *change*. The Windows degrade-vs-refuse error survived a previous review precisely this way.
- **Do not `rg` a full quoted template.** See the note at the top of this file.
