# Checklists

## Before starting work on a ticket
- [ ] Read the Jira ticket and the Slack thread. Find the first real error in the Orchestrator logs (`benops-ticket-investigation`).
- [ ] `git fetch`, create the branch off `origin/develop`, `git branch --show-current`.
- [ ] Invoke `uipath:uipath-rpa` before the first XAML edit.
- [ ] Confirm the project GUID if there is a similar sibling process.

## Before executing a test in Orchestrator (Staging)
- [ ] `uip login status` shows Staging.
- [ ] Package published to Staging (new version; Staging answers 409 for an existing one) and the Process points at it.
- [ ] Queue item populated with real, consistent data in the Salesforce format; item state is `New`.
- [ ] Robot available; Chrome pop-ups allowed and the UiPath extension installed as Current User (`feedback_uipath_chrome_extension`).
- [ ] If the process needs Python/Pillow or pwsh on the robot machine, confirm they exist (`feedback_staging_robot_missing_pillow`, `feedback_python_vdi`).
- [ ] The Credential asset in Staging is current (a stale Staging credential breaks navigation, not the code: `feedback_staging_bsca_credential_mismatch`).
- [ ] Studio closed if it holds file locks on the XAML.
- [ ] Start with `uip or jobs start`; do not use `uip rpa run` for tests.

## After the test
- [ ] Read the job log to the end, not just the final state. Capture the transaction reference.
- [ ] Confirm on the carrier portal or Salesforce that the change really happened.
- [ ] Say in the PR what was run end to end and what was not.

## Before opening a PR
- [ ] 2 to 3 transactions tested in Staging when the change touches the happy path (the PR body only says that it was tested, no ID table).
- [ ] Branch merged with `origin/develop`; the diff shows only the ticket files.
- [ ] `projectVersion` bumped; `dependencylock.json` exact; only `Gusto_*` deps in bots; framework Windows/Portable.
- [ ] No file under `Libraries/` changed, or a dedicated lib PR exists and is linked.
- [ ] Every new activity type was verified to exist in the project.
- [ ] `/analyze` run on the branch; analyzer difference with the real uipcli understood.
- [ ] No secrets, no PII, no `.env`, no `.claude/`, no root `CLAUDE.md` staged.
- [ ] Commit message and PR body: English, plain text, no AI signature.

## After merge
- [ ] The `develop` build is green (deploy step ran, not `waiting_failed`).
- [ ] `uip or packages list` shows the new version in Production.
- [ ] `uip or processes list` shows the Process on that version; if not, ask for approval to rebind with the real ProcessKey and note the version delta.
- [ ] Switch the tenant back to Staging.
- [ ] Jira closing comment (simple, non-technical, English), memory and `work_state.md` updated.
- [ ] After the next scheduled rounds, check that new items actually process (logs by hour), not only that the deploy succeeded.
