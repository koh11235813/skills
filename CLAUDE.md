# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This repo is a collection of Claude Code skills, distributed via `npx skills add koh11235813/skills`. It's markdown-only — there is no build, test, or lint step. The only CI is `.github/workflows/validate-skills.yml`, a shell check that each `skills/*/SKILL.md` has a frontmatter block whose `name` matches its directory and whose `description` is non-empty.

## Skill structure convention

Each skill lives in its own directory under `skills/` containing a `SKILL.md` file with YAML frontmatter (`name`, `description`) followed by the skill's instructions. A skill may include an optional `references/` subdirectory for supporting docs it links to (see `skills/explore-grill-build/` for an example of this layout).

## Adding a new skill

- Create a new directory `skills/<name>/`, named after the skill in kebab-case.
- Add `SKILL.md` with `name` and `description` frontmatter. The `description` drives auto-invocation, so it must state clearly what the skill does and when to use it.
