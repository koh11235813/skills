---
name: tmux-control
description: "Drive interactive terminal sessions with tmux: spawn another agent CLI (codex, claude, opencode, hermes) in a pane and wait for its prompt, send keys to it, read its output, and share a session over ssh with a human or another agent. Use for anything interactive, long-lived, or observed by someone else. Not for one-shot commands or non-interactive background jobs."
---

# tmux-control

tmux turns a terminal into something you can attach to, detach from, read programmatically, and hand to someone else. This skill covers three uses of that: running another agent's CLI in a pane you control, reading and steering an interactive program that expects a human, and sharing a live session with a person or a peer agent over ssh.

## When to use this

| Situation | Use |
|---|---|
| One command, you want its output | The normal shell |
| Long non-interactive job (build, test suite) | Your harness's background execution |
| Interactive TUI or REPL that expects a human | tmux |
| A session that must survive disconnect | tmux |
| A session a human or another agent will also watch | tmux |
| Another agent's CLI, driven over many turns | tmux |

If the work fits the first two rows, tmux only adds a layer that can silently swallow your input.

## Targets

Sessions, windows and panes address as `session:window.pane`, for example `codex-0:codex.0`. A bare session name means its current pane, which is fine for a single-pane session and ambiguous for anything else. Prefer the full form once a session has more than one pane.

```bash
tmux ls
tmux list-windows -t codex-0
tmux list-panes -a -F '#S:#W.#P #{pane_current_command}'
bash scripts/find-sessions.sh -q codex
```

## Spawn an agent CLI

Create a **shell** session, then type the CLI into it. Do not pass the CLI as the session's command:

```bash
# Wrong: the pane dies the moment codex exits, taking its last output with it
tmux new-session -d -s codex-0 -c /path/to/repo 'codex'
```

With a shell as the pane's process, the pane survives the CLI exiting, so you can still `capture-pane` the error that killed it.

```bash
# 1. shell session, detached, in the target directory
tmux new-session -d -s codex-0 -c /path/to/repo

# 2. launch the CLI (text and Enter as two separate calls, see below)
tmux send-keys -t codex-0 -l -- 'codex'
tmux send-keys -t codex-0 Enter

# 3. wait for it to be ready BEFORE sending anything else.
#    <ready-marker> is a placeholder: derive it from a real capture, see below.
bash scripts/wait-for-text.sh -t codex-0 -p '<ready-marker>' -T 60

# 4. confirm what you are actually looking at
tmux capture-pane -p -t codex-0 | tail -20
```

Step 3 is the one people skip. An agent CLI takes seconds to load its config, auth, and MCP servers, and keystrokes sent before its input widget exists are dropped with no error. Always wait for a ready marker, then look at the pane.

Ready markers differ per CLI and change between versions, so do not hardcode one from this document. Capture the pane once by hand, pick a string that only appears when the prompt is live, and use that. `wait-for-text.sh` exits non-zero and dumps the recent pane content to stderr on timeout, which tells you what to match on next time.

## Send input

**Send the text and the Enter as two separate `send-keys` calls.** Two independent reasons:

1. `-l` means "literal", so `send-keys -t X -l -- 'hello' Enter` sends the five characters `E n t e r` as part of the text. This is wrong on every terminal and every CLI.
2. Without `-l`, combining them has still been observed to fail: in a Codex TUI, text plus `Enter` in one call left the text sitting unsubmitted in the input box (`../explore-grill-build/references/harness-adapters/claude-code.md`, observed 2026-09-06). The mechanism was not established, so treat this as an observed effect rather than a rule about bracketed paste, and split the calls as the safe default.

```bash
tmux send-keys -t codex-0 -l -- 'Please implement phase 2 and reply when done.'
tmux send-keys -t codex-0 Enter
tmux capture-pane -p -t codex-0 | tail -5   # confirm it was actually submitted
```

Always verify submission with a capture. "I sent it" is not evidence it arrived.

Control characters go without `-l`:

```bash
tmux send-keys -t codex-0 C-c        # interrupt
tmux send-keys -t codex-0 C-d        # EOF
tmux send-keys -t codex-0 Escape
```

`C-c` is not uniformly "cancel the current thing". In an observed Hermes session it ended the entire session rather than the running goal. Check `references/agent-cli-quirks.md` before interrupting a CLI you have not interrupted before.

Never send secrets with `send-keys`. They land in the pane's scrollback, which anyone attached to the session can read, and which your own `capture-pane -S -` will happily print back into a transcript.

## Read output

```bash
tmux capture-pane -p -t codex-0              # visible pane
tmux capture-pane -p -t codex-0 -S -         # full scrollback
tmux capture-pane -p -J -t codex-0 -S -200   # last 200 lines, wrapped lines joined
```

`-J` matters when you grep: without it a long line that wrapped is two lines, and your pattern that spans the wrap point never matches.

When a CLI shows an approval or selection prompt, read the prompt before answering it:

```bash
tmux capture-pane -p -t codex-0 | tail -20
```

Answer only a prompt you have read and understood. Do not pattern-match `y/N` and send `y`; the same shape of prompt asks both "install this dependency?" and "overwrite your working tree?".

## Lifecycle

`#{pane_current_command}` tells you whether the CLI is still the foreground process, not whether it is busy. It reads `codex` both while the agent is thinking and while it sits idle at its prompt; it only changes when the CLI exits and the shell takes over. To tell idle from working, compare two captures separated by a few seconds:

```bash
a=$(tmux capture-pane -p -t codex-0 | tail -30)
sleep 5
b=$(tmux capture-pane -p -t codex-0 | tail -30)
[ "$a" = "$b" ] && echo idle || echo working
```

Unchanged output means "nothing is being printed", which is the best available signal, not proof the agent has stopped. Treat a quiet pane as a reason to look, not as permission to act.

Do not start a second agent that writes to a working tree while the first may still be running there. A stale-looking pane is not evidence the first writer finished. This is the same rule as the manager loop in `../explore-grill-build/references/manager-loop.md`, which also covers how to verify a phase before dispatching the next one.

```bash
tmux rename-session -t old new
tmux kill-session -t codex-0
```

## Share a session

A tmux session is a terminal that more than one process, person, or machine can hold at once. That is what makes it useful beyond automation.

```bash
tmux attach -t codex-0        # a human joins; both see and control the same pane
tmux attach -r -t codex-0     # read-only: watch without being able to type
```

Read-only attach is the right default for an observer. It lets someone follow an agent's work without the risk of their stray keystroke landing in the agent's input box.

Across ssh, let tmux own the session so a dropped connection does not kill the work:

```bash
ssh -t host 'tmux new -A -s work'   # attach if it exists, otherwise create it
```

`new -A` is idempotent, so the same command reconnects you after a disconnect. The session and everything running in it survive the ssh connection dying.

To share with a different user or a process that cannot reach your default tmux socket, put the socket somewhere both sides can open:

```bash
tmux -S /tmp/shared-tmux/sock new-session -d -s work
chmod 770 /tmp/shared-tmux/sock
tmux -S /tmp/shared-tmux/sock attach -t work
bash scripts/find-sessions.sh -S /tmp/shared-tmux/sock
```

Handing someone access to a socket hands them full control of **every** session on that socket, including the ability to run commands as the socket's owner. Use a socket dedicated to what you intend to share, never your default one. `find-sessions.sh -A` scans a directory of such sockets; set `TMUX_CONTROL_SOCKET_DIR` to point at it.

## Using agmsg alongside this

tmux and the separately installed `agmsg` skill solve different halves of multi-agent work. tmux starts a peer, watches it, and delivers keystrokes. agmsg delivers messages between agents and keeps their history. Neither replaces the other.

The one place they meet: after sending an agmsg message to a peer that is sitting idle, the peer may not pull its inbox until something starts a turn. A tmux nudge starts one.

```bash
tmux send-keys -t codex-0 -l -- '$agmsg'
tmux send-keys -t codex-0 Enter
tmux capture-pane -p -t codex-0 | tail   # confirm the turn started
```

Whether a nudge is needed depends on the peer's delivery mode: a Claude Code peer with its `Monitor` running receives agmsg messages without one. See `references/agent-cli-quirks.md` and the agmsg skill's own documentation.

## Scripts

Invoke them as `bash scripts/<name>` rather than relying on the executable bit, which may not survive installation.

- `scripts/wait-for-text.sh -t <target> -p <pattern>` polls a pane until the pattern appears. `-F` for a fixed string, `-T` timeout seconds (default 15), `-l` how many history lines to inspect. On timeout it prints those lines to stderr and exits non-zero, so a failed wait tells you what the pane actually contained.
- `scripts/find-sessions.sh [-L name | -S path | -A] [-q pattern]` lists sessions on a socket, with `-A` scanning every socket under `TMUX_CONTROL_SOCKET_DIR`.

Both are adapted from [openclaw/openclaw](https://github.com/openclaw/openclaw/tree/main/skills/tmux) (MIT), whose tmux skill is the basis for the control and capture sections here.

## Related

- `references/agent-cli-quirks.md` — per-CLI behavior that has actually been observed, with sources.
- `../explore-grill-build/references/manager-loop.md` — running a persistent implementer through ordered, verified phases.
- `../explore-grill-build/references/harness-adapters/` — the evidence record behind the quirks, per harness.
