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

The loop, every time:

1. **Start from a current `main`** — `git checkout main && git pull`, then branch off it.
2. **Catch up before asking for a merge.** `main` is protected and will not take a branch that is behind it. When GitHub says the branch is out of date — before opening the PR, or later, if `main` moves while the PR is open — **merge `main` into the branch**. Don't rebase: PRs are closed by squash, so the whole branch arrives on `main` as one Conventional Commit and any merge commit inside it disappears. Rebasing buys nothing and rewrites published history.
3. **Open the PR and stop.** Approving and merging are the maintainer's, by hand. Agents don't run `gh pr merge`.
4. **Delete the branch once the PR is merged**, on the remote and locally, so only `main` is left. `git branch -d` refuses a squashed branch — confirm with `git cherry -v main <branch>`, which marks an already-upstream commit `-`, and then `git branch -D`.

**Comments.** The default is none. The code says what it does; a comment is for what it cannot — why a non-obvious choice was made, a platform behaviour that contradicts the obvious reading, a pointer to the ADR that settled it. Anything restating the line below it is noise, and noise is what makes the rare necessary comment easy to skip. Reach for a clearer name or a smaller function before reaching for a comment to explain an unclear one. The same budget applies to `///` doc comments: a type whose name and shape already say what it is does not need a paragraph above it.

**Releases.** Pushing a `v*` tag builds, packages a `.dmg`, generates the changelog and publishes a GitHub Release. Version numbers are chosen by hand, not derived from commits.
