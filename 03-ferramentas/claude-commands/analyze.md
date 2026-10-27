---
name: analyze
description: Review current branch changes for XAML issues, naming conventions, selector quality, and uncommitted modifications. Run before any PR.
sdlc_phases: [test]
allowed-tools: [Bash(git *), PowerShell, Read, Grep, Glob]
---

# /analyze — Review Current Branch Changes

No arguments needed. Analyzes everything changed on the current branch vs develop.
Respond in English.

---

## Execution Plan

### STEP 1 — Read branch state

Run all git commands from the current working directory — no hardcoded paths.

```powershell
# Current branch
git branch --show-current

# Files changed vs develop
git diff develop..HEAD --name-only

# Full diff of changed files
git diff develop..HEAD
```

### STEP 2 — For each changed XAML file, run these checks

#### Check A — Activity types (CRITICAL)
For every `ui:SomeActivity` tag found in the diff additions (`+` lines), verify that activity type already exists in the project:

```powershell
Select-String -Path ".\**\*.xaml" -Pattern "ui:ActivityName" -Recurse
```

If an activity type appears in the diff but NOT elsewhere in the project → **flag as HIGH risk**.

#### Check B — Library files (CRITICAL)
If any changed file path contains `Libraries/` → **flag as CRITICAL**: changes to shared libraries affect all processes.

#### Check C — Selector quality
In changed XAML files, look for selectors (strings inside `selectorValue=` or similar). Flag selectors that:
- Use `idx=` attributes (fragile, position-based)
- Use `parentid=` with long generated IDs
- Have no `aria-role`, `name`, or semantic attributes

Prefer: `aria-role`, `aaname`, `name`, `automationid`.

#### Check D — Naming conventions
Check arguments and variables in changed XAML:
- Arguments must follow: `in_Name`, `out_Name`, `io_Name` (PascalCase with prefix)
- Variables must be camelCase
- Flag anything that deviates

#### Check E — Uncommitted changes
```powershell
git status --short
```
Flag any modified files that are NOT staged (might be forgotten).

---

## Output Format

```
## Branch Analysis — [branch-name]

**Files changed:** [N] | **Commits:** [N]

### Critical
[Issues that could break the build or affect other processes — must fix before PR]

### Attention
[Issues that should be reviewed — fragile selectors, naming violations, etc.]

### OK
[What looks good — activity types verified, no Library edits, etc.]

### Pre-PR Checklist
- [ ] All new activity types verified in the project
- [ ] No Library files modified
- [ ] Transactions tested in Orchestrator
- [ ] Transaction IDs ready for PR body
```

If no issues are found in a category, say "No issues found" in one line — do not omit the category.
