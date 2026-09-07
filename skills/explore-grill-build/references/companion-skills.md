# Companion skills

`explore-grill-build` runs on its own. Three separately installed skills make Phase 1 and Phase 3 sharper when they are present; when they are not, the workflow falls back to the inline versions described in `SKILL.md` and keeps going.

| Skill | Used in | When absent |
|---|---|---|
| `grilling` | Phase 1, always | Inline interview in dependency-aware rounds |
| `domain-modeling` | Phase 1, only when the domain-docs decision selects it | Inline glossary/ADR discipline |
| `tdd` | Phase 3 | Inline Red → Green → Refactor loop |

Recommended source is [`mattpocock/skills`](https://github.com/mattpocock/skills). One command installs all three:

```bash
npx skills add mattpocock/skills --skill grilling domain-modeling tdd
```

A skill under another name that does the same job (for example a harness-native TDD skill) counts as present; do not suggest this install just because the literal name is missing.

Do not install or reference `grill-me` or `grill-with-docs`. Upstream they are one-line wrappers around `grilling` and `grilling`+`domain-modeling`, flagged so the model cannot invoke them; they never show up in a model-visible skill listing even when installed, which is why this workflow names the underlying skills directly.
