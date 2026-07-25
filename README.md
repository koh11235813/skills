# skills

A collection of [Claude Code](https://claude.com/claude-code)/[codex](https://github.com/openai/codex) skills by [koh11235813](https://github.com/koh11235813).

[日本語版はこちら](README_ja.md)

## Installation

```bash
npx skills add koh11235813/skills
```

## Available skills

- **explore-grill-build** — End-to-end workflow for implementing a nontrivial feature or fix, from first look to committed code. Explores the codebase, interviews to turn vague requirements into a written plan, gets that plan reviewed, implements it test-first, and gates on review before anything is committed.

- **codex-harness-behavior** - Operational model of how the codex (codex-rs) agent harness constrains, gates, and corrects agent behavior

- **tut-slide** — Academic presentation slides in the Toyohashi University of Technology style (white background, red/black double rule, centered bold titles), as LaTeX Beamer (recommended) or Marp Markdown. Ships a Beamer theme, a Marp theme, and templates covering title / bullet+highlight / two-column / figure placement / math / tikz / algorithm / code layouts. See the logo note below.

## Note on the tut-slide logos

The Toyohashi University of Technology logos are **not** included in this repository. Their copyright belongs to the university ([site policy](https://www.tut.ac.jp/site-policy.html)), so they cannot be redistributed here.

To get the full branded look, obtain the logos yourself and place them as `images/tut-logo.png` (top-right university name logo) and `images/tut-logo2.png` (bottom-left T mark) next to your slide source. Use them within the scope permitted by the university. Without the images the templates still build — they simply render unbranded. Details are in `skills/tut-slide/SKILL.md`.

## License

[MIT](LICENSE)
