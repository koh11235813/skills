# skills

A collection of [Claude Code](https://claude.com/claude-code)/[codex](https://github.com/openai/codex) skills by [koh11235813](https://github.com/koh11235813).

[日本語版はこちら](README_ja.md)

## Installation

```bash
npx skills add koh11235813/skills
```

### Optional companion skills

`explore-grill-build` works on its own, but its interview and TDD phases are built around three separately installed skills: `grilling` (the interview), `domain-modeling` (glossary/ADR upkeep, only when the repo has or wants that structure), and `tdd` (the test loop). When one is missing the workflow says so once and falls back to an inline version. Recommended source is [mattpocock/skills](https://github.com/mattpocock/skills):

```bash
npx skills add mattpocock/skills --skill grilling domain-modeling tdd
```

### External dependencies

Most skills here are markdown only. `jev-recommendation-rate` is the exception: it calls the [TypeSafe](https://typesafe.ai) API from a shell script, so it needs `curl`, `jq`, and a `JEV_API_KEY` in the environment.

`jq` is not part of a base install on most Linux distributions (recent macOS ships it):

```bash
brew install jq        # macOS, if missing
sudo apt install jq    # Debian/Ubuntu
sudo dnf install jq    # Fedora
export JEV_API_KEY=... # key from https://typesafe.ai
```

When any of them is missing, `jev-recommendation-rate` says so and the question goes out without recommendation rates. Every other skill in this repository is unaffected.

## Available skills

- **explore-grill-build** — End-to-end workflow for implementing a nontrivial feature or fix, from first look to committed code. Explores the codebase, interviews to turn vague requirements into a written plan, gets that plan reviewed, implements it test-first, and gates on review before anything is committed.

- **jev-recommendation-rate** — Attaches a recommendation rate to every option of a multiple-choice question, computed by TypeSafe's Jev model, so a question shows how the probability mass splits across its options rather than only which one was picked. Applies to `AskUserQuestion` calls and to grill rounds from `grilling`/`explore-grill-build`. Ships `score-options.sh`, which scores a whole round in one request against a cached context brief and reports its token cost. Requires `curl`, `jq` and `JEV_API_KEY`.

- **codex-harness-behavior** - Operational model of how the codex (codex-rs) agent harness constrains, gates, and corrects agent behavior

- **tmux-control** — Driving interactive terminal sessions with tmux: spawning another agent's CLI in a pane and waiting for its prompt before sending anything, sending keys and reading output safely, and sharing a live session over ssh with a human or a peer agent. Ships `wait-for-text.sh` and `find-sessions.sh`, plus a record of per-CLI quirks observed when driving codex, hermes and opencode through tmux.

- **tone-control** — Speak in a chosen character voice (tsundere ojousama, little sister, Osaka auntie, gyaru in three flavours, Zundamon, DIO, Sakura Saber, Ereshkigal, Ishtar, downer genius). One file per voice under `references/`, each defining pronouns, sentence endings, stock phrases and example lines. The Interaction contract shared by every voice (confirm ambiguous requirements, confirm irreversible changes, restate Goal/Non-goals/Constraints/Success criteria) lives in `SKILL.md` and is never repeated per voice.

- **tut-slide** — Academic presentation slides in the Toyohashi University of Technology style (white background, red/black double rule, centered bold titles), as LaTeX Beamer (recommended) or Marp Markdown. Ships a Beamer theme, a Marp theme, and templates covering title / bullet+highlight / two-column / figure placement / math / tikz / algorithm / code layouts. See the logo note below.

## Note on the tut-slide logos

The Toyohashi University of Technology logos are **not** included in this repository. Their copyright belongs to the university ([site policy](https://www.tut.ac.jp/site-policy.html)), so they cannot be redistributed here.

To get the full branded look, obtain the logos yourself and place them as `images/tut-logo.png` (top-right university name logo) and `images/tut-logo2.png` (bottom-left T mark) next to your slide source. Use them within the scope permitted by the university. Without the images the templates still build — they simply render unbranded. Details are in `skills/tut-slide/SKILL.md`.

## License

[MIT](LICENSE)
