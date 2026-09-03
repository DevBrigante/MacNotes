# MacNotes

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Conventions

**Language.** Code, glossary, ADRs, issues and commit messages are in English. Conversation with the user is in pt-BR. The README carries both languages.

**Commits.** Conventional Commits — `feat(notch):`, `fix(planner):`, `chore:`. `git-cliff` generates each release's changelog from them, so an unstructured message is a missing changelog entry.

**Branching.** Trunk-based: short-lived branches off `main`, one PR each, merged once the build check is green. `main` is protected. No `develop`, no `release/*`, no `hotfix/*`.

**Releases.** Pushing a `v*` tag builds, packages a `.dmg`, generates the changelog and publishes a GitHub Release. Version numbers are chosen by hand, not derived from commits.
