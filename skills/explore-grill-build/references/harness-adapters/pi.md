# Pi adapter

Read this adapter before the runtime capability check in a Pi session. Pi supplies the skill-loading mechanism and basic tools, but subagents and plan mode are not core features. Separate core behavior, the optional subagent example, and local extensions; confirm each capability in the current session.

## Evidence and scope

Checked against the installed `@earendil-works/pi-coding-agent` **1.2.0** documentation and subagent example, plus the current session's visible tools and local agent/extension definitions, on **2026-10-14**. Public references:

- [Pi overview](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md) — core features and extension-based customization.
- [Skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md) — discovery, loading, relative paths, and explicit skill commands.
- [Subagent example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent) — agent definitions, dispatch, model inheritance, and results; `runSingleAgent` in `index.ts` starts each child with `--no-session`.
- [Command line](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/cli.md) and [extensions](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md) — tool selection, extension/MCP reach, and non-interactive UI limits.

These public links track upstream; the observations below describe the installed version, not a promise about every Pi installation. The `questionnaire` tool is a separate example extension shipped with Pi, not part of the core or the subagent example; the `worktree` argument comes from a local extension. This adapter configures neither agents nor extensions.

## Capability mapping

| Capability | Evidence to confirm in this session | Safe fallback |
|---|---|---|
| `plan_artifact` | `write` can create the common `/tmp/explore-grill-build/<unique-session>/<slug>.md` artifact and later readers can access it | Pass the complete plan text; ask for a writable path if needed. No native plan-mode artifact is assumed. |
| `delegate_readonly` | An existing agent's actual tool set and enforcement exclude every mutation path, including shell, extension, MCP, and nested delegation tools | Survey inline; at external-review gates, report the missing eligible reviewer and obtain the explicit human exception required by [external-review.md](../external-review.md). |
| `delegate_parallel` | The exposed `subagent` schema supports `tasks`, and dispatch returns inspectable results for every child | Use eligible delegates sequentially, or survey inline. A background shell job alone is not a delegate join. |
| `delegate_model_select` | An existing selectable agent declares a verified model tier in its frontmatter and that model is reachable | Use the inherited session model; skip the weak-model probe with the reason recorded. |
| `delegate_write_isolated` | A local `worktree: true` implementation and its guard enforce per-child write roots, with an explicit parent integration path; shared outputs and fixtures are accounted for | Implement sequentially. A visible worktree argument or disjoint files alone do not confirm isolation. |
| `delegate_persistent` | A separate mechanism can re-message the same live context and return an inspectable reply | Use the ordinary sequential slice loop. The inspected subagent example does not provide this capability. |
| `skill_discovery` | The system prompt advertises available skill names, descriptions, and file paths | Use the common workflow's inline companions; an unverified listing is not evidence that a skill is missing. |
| `skill_invoke` | `read` can load the advertised `SKILL.md` | Use inline instructions; do not invent a `Skill` tool. |
| `diff_access`, `test_runner` | `bash` and current permissions permit inspecting the diff and executing the target repo's checks | Report blocked checks; do not claim verification from a delegate's completion statement. |
| `human_confirmation` | A user can explicitly reply in the conversation, or an available interactive question tool can return their decision | Return a checkpoint and wait. Non-interactive execution cannot approve its own build, review exception, integration, or commit. |

## Skills, artifacts, and human decisions

Use the advertised skill path with `read`; loading instructions is Pi's model-side invocation mechanism. Resolve every relative reference from that skill's directory. `/skill:<name>` and `/reload` are user commands, not tools for the agent to call. A skill hidden by `disable-model-invocation: true` cannot be assumed discoverable; use the underlying companions named by the common workflow.

Use the common plan file as the source of truth. Give delegates its absolute path and confirm readability; if a child cannot read it, supply the complete text. Worktrees start from HEAD in the observed local extension, so they do not include uncommitted plan or implementation files from the parent workspace.

When a tool that asks the user structured questions is exposed, use its actual schema for interview rounds and human gates; the bundled `questionnaire` example, for instance, takes `questions` with `id`, `prompt`, and `options`. Otherwise ask in ordinary conversation and stop for the reply. A canceled question is not approval. Keep build approval, a review exception, worktree integration approval, and commit approval distinct.

## Subagent dispatch

Discover the available agent definitions before choosing an `agent` name. The example discovers user agents under the agent directory's `agents/` (normally `~/.pi/agent/agents/`); project agents under `.pi/agents/` require `agentScope: "project"` or `"both"`. Prefer the default user scope, and preserve project-agent confirmation. Agent names describe roles, not permissions or model tiers.

The inspected schema supports exactly one mode per call:

- Single: `{ "agent": "<existing-agent>", "task": "<complete task>" }`.
- Parallel: `{ "tasks": [{ "agent": "<existing-agent>", "task": "<task>" }, ...] }`. Phase 0 still allows at most three explorers, regardless of the extension's higher limit.
- Chain: `{ "chain": [{ "agent": "<existing-agent>", "task": "<task>" }, { "agent": "<existing-agent>", "task": "<task using {previous}>" }] }`. Each step starts a fresh child; `{previous}` passes output text, not conversation state.

These are templates, not literal agent names. Include the absolute artifact/workspace paths, capability restrictions, and required result in each task. Inspect every child's errors and output before accepting the dispatch; a truncated or failed result does not satisfy a review gate.

Model selection belongs to the existing agent definition's `model` frontmatter, not an invented per-call `model` argument. Without an override, the inspected example inherits the dispatching session's model and thinking level. The example's sample agents each declare a `model` (`scout` a Haiku tier, the others a Sonnet tier), but local copies may remove or change it; read the installed definition and confirm the model is reachable instead of relying on the role name.

### Write-capable delegates

Parallel build slices need a write-capable agent. The example ships `worker`, a general-purpose agent with no `tools` restriction, and its install instructions copy it to the user agent directory with the other sample agents; its `/implement` and `/implement-and-review` prompts use it as the implementer. When such an agent is registered, prefer it for write delegates after reading its definition for `tools` and `model`. Starting it with `--no-session` means it cannot serve as the persistent implementer of the manager loop, and it never satisfies a read-only or external-review gate.

### Read-only discovery and review

Inspect both the agent definition and the child runtime's effective tool reach. A reader-only list such as `tools: read, grep, find, ls` is a candidate, not sufficient evidence by itself: loaded extensions can replace tools or expose other execution paths, and CLI `--tools` selection alone does not remove all MCP reach. Confirm enforcement over the full child tool set before marking `delegate_readonly` confirmed.

In the observed local setup, `scout` and `reviewer` expose `bash`, and the inherited guard mode is `normal`, not `readonly`. The reviewer's instruction to use only read-only commands is not enforcement. `planner` lists only reader tools, but its frontmatter alone does not verify the loaded extension/MCP paths. None of these role names automatically passes the eligibility gate. These three local definitions drop the sample's `model` line and inherit the session model. The local `worker` keeps full tools and declares a different model, `deepseek/deepseek-v4-flash-0731`, which is listed in the local model store but was not dispatched in this check.

Use an eligible fresh-context reviewer when one is confirmed, preferring a different provider as specified in [external-review.md](../external-review.md). Otherwise stop at the review gate for a human exception. Do not silently replace the external review with a write-capable `reviewer` or self-review, or weaken permissions to make a child run.

### Local worktree extension

Only use `worktree: true` when that argument is exposed and its guard-backed behavior is confirmed. It creates one worktree per single/parallel task, or one shared worktree for all chain steps; it cannot be combined with explicit `cwd`. A chain sharing a worktree still does not share a model context. The inspected local guard documentation reports no end-to-end Pi worktree test and warns of shared Git metadata and execution paths through child-controlled Git configuration; `delegate_write_isolated` remains unverified in this session.

The observed wrapper fails closed when its guard is absent. Worktrees are under `.pi-worktrees/`, branched from HEAD; uncommitted parent changes are absent. Ports, environment variables, and shared dependencies such as `node_modules` are not isolated by worktree creation. Verify that no slice can mutate another slice's shared output before parallel writes.

Inspect the actual worktree changes, not just the returned summary, and get the user's approval before integration. Nothing is automatically merged or removed. Do not commit merely to transfer uncommitted parent state, and obtain authorization before cleanup. If the guard or isolation cannot be verified, keep writes sequential.

## Continuation and blocked execution

The inspected `subagent` starts a new process with `--no-session` for every task and exposes no resume/thread identifier. Reusing an agent name, passing `{previous}`, or sharing a worktree does not confirm `delegate_persistent`. A local `/goal`, messaging extension, or `monitor`/`jobs` pair also needs its own verified same-context delivery/reply contract before it can support the manager loop.

Shell permissions may prevent a nested Pi CLI from starting even when the parent session works. In this session, `pi --help` reported `EPERM` creating `~/.pi/agent/settings.json.lock`; a shell-launched CLI review was therefore not established as an alternative. Treat startup, authentication, sandbox, or artifact-access failures as unavailable capabilities. Report the blocker and follow the relevant fallback; changing the user's settings, credentials, extensions, or agent definitions is a separate task requiring authorization.

From Claude Code on 2026-10-31, `pi -p --session-id <uuid>` preserved context across invocations; see [Implementer CLI](claude-code.md#implementer-cli) for the commands and evidence. This path was not checked from inside a Pi session, so confirm it locally before relying on it.
