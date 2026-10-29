# Security

Company data (Gusto, Guideline, Symmetry, Mosey) must not leave company control. Local work with real data is normal and free: read, query, debug, local files, Staging runs. The rules below are about egress.

## Never
- Send company data to a personal or public destination: personal or public GitHub, gists, Pages, personal email or drive, public paste services, "anyone with the link" shares.
- Commit secrets: passwords, API keys, tokens, PATs, private keys, connection strings, `.env`, `~/.uipath/.auth`, `.credentials.json`. Use env vars or Orchestrator assets.
- Commit real PII or confidential figures in tracked files: SSN/EIN, bank or card numbers, DOB, wages, names, emails, addresses, phone numbers, revenue, headcount, pricing. Use synthetic samples. Uncommitted local fixtures are fine.
- Post to Slack outside the approved internal workspaces, or into external/Connect channels.
- Treat a client-side "password gate" as protection.

## Before anything that pushes, shares, posts or uploads
1. Name the destination out loud (repo, channel, recipient).
2. If it is external, unapproved or unclear: stop and ask Dio. If still unsure whether something is safe to publish, treat it as confidential and ask Security.
3. Approved distribution is gusto.com, guideline.com, symmetry.com, gustocare.com, mosey.com. A customer or partner gets only their own data, through approved channels.

## Specific to this work
- Queue items and test data come from real Production items. They stay in Staging and local files. Never paste SpecificContent with SSN or names into a PR, Jira comment or Slack message. Use the item reference (e.g. `500R...`) instead.
- Transaction logs and screenshots can contain PII: do not attach them to Jira/PRs; describe them.
- Credentials: only WHERE they live is documented (`../01-credentials/`). Never write a value in the hub, memory, a commit or a message.
- The hub (`Gusto-Dio/hub`) is private and was scanned for secrets and SSNs on 2026-10-28. Re-scan before each push. Pushing to it needs explicit approval from Dio (the auto mode blocks it; Dio runs the push with `!`). If there is any doubt that this repo counts as company-managed, ask Security.
- The repo remote is `github.com/Gusto/biztech-uipath-rpa` only. Do not add other remotes.
