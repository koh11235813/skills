---
name: jev-recommendation-rate
description: "Attach a recommendation rate to every option of a multiple-choice question, computed by the TypeSafe Jev model. Use right before calling AskUserQuestion with options, and right before emitting a grill round from the grilling or explore-grill-build workflow, so the reader sees how the probability mass is split across the options instead of only which one you picked. Needs JEV_API_KEY, curl and jq; without them, ask the question as usual."
---

# jev-recommendation-rate

A question with four options and one recommendation tells the reader what you picked but not how close the race was. Jev, TypeSafe's System One model, answers a Choice question with a probability for **every** option plus a `confidence` for how concentrated that distribution is. Show those numbers next to the options and the reader can see for themselves whether the second option was a near-miss or a non-starter.

This skill does not decide anything. It adds numbers to a question that a human still answers.

## When to use this

| Situation | Use this skill |
|---|---|
| `AskUserQuestion` with 2-4 concrete options | Yes |
| A grill round where each question carries 2-4 concrete options | Yes |
| An open-ended question with no enumerated options | No. There is nothing to score |
| A yes/no confirmation | No |
| Approval for a destructive or irreversible action | No. The human decides alone |
| `JEV_API_KEY`, `curl` or `jq` missing | No. Ask the question with no rates and say once that they were unavailable |

Do not invent options so that a question becomes scorable. If the question is genuinely open, leave it open.

## Step 1: cache the brief

Every question here sits on top of a codebase the model cannot see, and input tokens are billed. So write the shared context **once** and reuse it for the whole session.

Write `<scratchpad>/jev-brief.md`, at most ~500 tokens, covering:

- what this repository is for, from its `CLAUDE.md` or `README`
- the files and modules currently in play
- the decision this round of questions is serving

Before writing it, check whether it already exists. If it does and the topic has not moved, reuse it unchanged. Rewrite it only when the work shifts to a different part of the codebase or a different decision. Re-summarising the codebase per question is the one thing that makes this skill expensive.

## Step 2: one round, one request

`questions` is a map, so a whole round goes in a single request. Build the input for `scripts/score-options.sh` and pipe it in:

```json
{
  "brief_file": "/path/to/scratchpad/jev-brief.md",
  "decision": "One or two sentences on what this round decides.",
  "questions": [
    {
      "id": "impl",
      "question": "Which implementation form fits this repository?",
      "options": [
        { "key": "bash_curl_jq", "description": "A bash script using curl and jq. No language runtime." },
        { "key": "python_sdk", "description": "The official Python SDK. Adds a runtime dependency." }
      ]
    }
  ]
}
```

```bash
JEV_USAGE_LOG=<scratchpad>/jev-usage.log scripts/score-options.sh < round.json
```

Point `JEV_USAGE_LOG` at the scratchpad every time. Without it the log defaults to `$TMPDIR`, which outlives the session, and the running total stops meaning "this session".

The script adds a `none_of_these` option to every question by itself, so a bad option set cannot be forced to 100%. Do not add one yourself.

Never split a round into one request per question.

## Step 3: render the rates

**`AskUserQuestion`.** A `label` is 1-5 words, so the number does not fit there. Put it at the front of `description`:

```
推奨率 72% · confidence 0.81 / <the description you would have written anyway>
```

**A grill round.** `grilling` puts the options in the prose of the question body. Pull them out into lines so each one has somewhere to carry its number, then keep the `➡️` line exactly as before:

```
❓ **Q1** - **Implementation form**: <question body>

- bash + curl + jq（推奨率 72%）
- Python SDK（推奨率 24%）
- どれも違う（推奨率 4%）

➡️ bash + curl + jq。この repo は markdown だけで、言語ランタイムを持ち込みたくない。
```

Nothing else about the grilling output format changes.

## Step 4: let confidence decide who leads

`confidence` says how concentrated the distribution is, not whether the answer is right.

- **`confidence >= 0.7`**: put Jev's highest-probability option first and mark it `(Recommended)`.
- **`confidence < 0.7`**: change nothing about the order. Show the percentages and add one line saying the distribution is split, so the reader knows the ranking is not meaningful.
- **Your own recommendation disagrees with Jev's top option**: keep both. Say in one line that they differ and why you still prefer yours. Do not quietly drop either. In a grill round that line goes next to `➡️`; in `AskUserQuestion` it goes at the end of the `question` text, which is the only place that belongs to no single option.

`0.7` is a starting point, not a constant. TypeSafe's own guidance is that a threshold is not one number and has to be calibrated against your data and the cost of being wrong. Raise it when the question gates something expensive to undo; lower it when the options are all survivable.

## When the call fails

A missing key, an HTTP error, a timeout: in every case, ask the question as you would have without this skill and add one line saying the rates were unavailable. The question is the point; the numbers are decoration on top of it. Never block a round on the scorer.

The script's exit codes: `1` API or network failure, `2` `JEV_API_KEY` unset, `3` `curl` or `jq` missing.

## Cost

The script prints this call's tokens and the running total, and appends both to the file named by `JEV_USAGE_LOG`. A round of two questions over a ~180-token brief measured 759 input tokens, so a round costs a few hundred. If that number climbs across a session, the brief is being rewritten too often.

Three environment variables override the defaults: `JEV_USAGE_LOG` (default `$TMPDIR/jev-usage.log`), `JEV_API_URL` (default `https://api.typesafe.ai/v1/systemone`) and `JEV_MODEL` (default `jev-latest`).
