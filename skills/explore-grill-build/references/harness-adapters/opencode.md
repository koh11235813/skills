# OpenCode adapter

Use this adapter only after the current OpenCode session exposes the described tools and permissions. It records public documentation plus OpenCode source inspected at commit [`c9db6e9`](https://github.com/anomalyco/opencode/tree/c9db6e9a1fe181fad2259689ef4ad9a5e89fbd5b) on 2026-07-22.

## Capability mapping

- `task` creates a child-session delegate. It requires `description`, `prompt`, and `subagent_type`; reuse `task_id` only to continue that same child. [Source](https://github.com/anomalyco/opencode/blob/c9db6e9a1fe181fad2259689ef4ad9a5e89fbd5b/packages/opencode/src/tool/task.ts)
- Use configured `explore` for codebase reads and `scout` for external research only when those agent types are advertised. [Agents](https://opencode.ai/docs/agents/)
- `subagent_depth` defaults to `1`; do not expect children to fan out unless current configuration raises it. [Configuration](https://opencode.ai/docs/config/#subagent-depth)
- Configure a model on an agent when a genuine lower or stronger tier is needed. Otherwise the task inherits the invoking agent's model. [Agents: model](https://opencode.ai/docs/agents/#model)
- Background subagents are experimental and not restart-durable. Do not use them for a review or implementation gate. [CLI](https://opencode.ai/docs/cli/#experimental)

## Safety and artifacts

- `permission.task` and per-agent tool permissions are approval controls, not a process or filesystem sandbox. Confirm that write-capable tools are denied before treating a child as a read-only reviewer. [Permissions](https://opencode.ai/docs/permissions/)
- A task does not receive a per-task worktree. Use sequential writes unless an isolated worktree or branch and parent integration path are separately confirmed. [Task source](https://github.com/anomalyco/opencode/blob/c9db6e9a1fe181fad2259689ef4ad9a5e89fbd5b/packages/opencode/src/tool/task.ts)
- The `skill` tool loads instructions by `name`; it does not accept another harness's invocation arguments. Discover the skill first, then load it and provide the relevant plan or brief in subsequent context. [Skills](https://opencode.ai/docs/skills/)
- The inspected implementation creates `.opencode/plans/<timestamp>-<slug>.md` in a Git worktree. Treat this as an optional native-plan mirror only after confirming it is writable and shareable; the common workflow's `/tmp` plan artifact remains primary. [Source](https://github.com/anomalyco/opencode/blob/c9db6e9a1fe181fad2259689ef4ad9a5e89fbd5b/packages/opencode/src/session/session.ts#L331-L336)
