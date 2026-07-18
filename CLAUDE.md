# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This repo is a collection of Claude Code skills, distributed via `npx skills add koh11235813/skills`. It's markdown-only — there is no build, test, lint, or CI tooling.

## Skill structure convention

Each skill lives in its own top-level directory containing a `SKILL.md` file with YAML frontmatter (`name`, `description`) followed by the skill's instructions. A skill may include an optional `references/` subdirectory for supporting docs it links to (see `explore-grill-build/` for an example of this layout).

## Adding a new skill

- Create a new top-level directory named after the skill, in kebab-case.
- Add `SKILL.md` with `name` and `description` frontmatter. The `description` drives auto-invocation, so it must state clearly what the skill does and when to use it.
