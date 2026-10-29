# Rules

Short, normative, loaded BEFORE acting. Lessons and pitfalls with the full story stay in `06-learnings/` (the rules here cite them by file name). If a rule here and a memory disagree, this folder wins; fix the memory.

## Load order (every session, before the first action)
Always read: `security.md`, `git-and-pr.md`, `session-protocol.md`.
Then by task:

| Task | Also read |
|---|---|
| Edit/create/debug any `.xaml`, `.cs`, `project.json`, selector | `xaml-and-skills.md`, `conventions.md` |
| Open a PR, bump versions, touch a lib, `dependencylock.json` | `buildkite-and-dependencies.md`, `checklists.md` |
| `uip`, Orchestrator, queues, assets, jobs, Production anything | `production-and-uip.md`, `checklists.md` |
| Slack, Jira, status updates | `../02-platforms/team-and-channels.md` |
| Which skill or command to use | `../03-tools/skills-and-commands.md` |

## Files
- `security.md`: what may never leave the machine, and what needs a destination check.
- `git-and-pr.md`: branches, commits, PR body, language, what never gets committed.
- `xaml-and-skills.md`: the XAML edit protocol, activity verification, library rule, mandatory skills.
- `buildkite-and-dependencies.md`: CI checks, lock, version bump, deploy behavior.
- `production-and-uip.md`: tenants, approvals, rebind, Production safety.
- `checklists.md`: pre-PR, pre-execution, post-execution, post-merge.
- `conventions.md`: naming, selectors, activity gotchas.
- `session-protocol.md`: what to read at the start and what to write at the end of a session.
