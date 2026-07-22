# Hermes Agent adapter

Use this adapter only when the current Hermes session exposes `delegate_task` and its runtime behavior is working. Evidence below comes from Hermes Agent source at commit [`e57918a`](https://github.com/NousResearch/hermes-agent/tree/e57918ac800121cf9c2956fe55e27df3ea80b562), inspected on 2026-07-22, plus a same-day runtime failure report.

## Capability mapping

- `delegate_task` supports a single `goal` or a parallel `tasks` batch. Its configured concurrency default is three; both modes return immediately and deliver results asynchronously. Leaf delegates are flat by default and cannot delegate again. [Source](https://github.com/NousResearch/hermes-agent/blob/e57918ac800121cf9c2956fe55e27df3ea80b562/tools/delegate_tool.py#L3334-L3451)
- Hermes has no built-in read-only explorer role. Emulate one only when the delegate's actual toolsets and permissions exclude write-capable tools; otherwise the parent performs the survey.
- A subagent model cannot be selected per `delegate_task` call. Children inherit the parent unless the global delegation model is pinned in configuration, so skip the weak-model probe when no genuinely lower tier is already configured. [Source](https://github.com/NousResearch/hermes-agent/blob/e57918ac800121cf9c2956fe55e27df3ea80b562/tools/delegate_tool.py#L3430-L3439)
- Hermes exposes installed skills in its available-skills context. Use its bundled `plan`, `test-driven-development`, and `requesting-code-review` skills only after discovery confirms availability. Its `.hermes/plans/` path is an optional native-plan mirror, not the portable primary artifact.

## Safety and known blocker

- Separate delegate contexts and terminal sessions do not by themselves prove isolated write integration. Without a confirmed worktree/branch/sandbox and parent integration path, keep write-capable slices sequential.
- The bundled `requesting-code-review` workflow provides a fresh reviewer context, but use it as this workflow's external-review gate only when the selected reviewer has enforced read-only tools. Prompt text alone is not enough.
- In the 2026-07-22 investigation session, both batch and single `delegate_task` calls failed immediately with `DaemonThreadPoolExecutor` lacking `_initializer`. Treat delegation as unavailable in sessions showing this failure; report the blocker and use the common sequential or inline fallback.
- Hermes command approvals do not replace this skill's explicit human commit confirmation. Ask the user before committing even after a review skill passes.

## Cross-runtime review

Hermes has no built-in Codex-style cross-runtime reviewer. An `agmsg` exchange or another external process is eligible only if it creates a fresh reviewer with enforced read-only execution; otherwise follow the human-exception path in `external-review.md`.
