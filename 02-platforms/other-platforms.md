# Other platforms

- **GitHub:** repo `Gusto/biztech-uipath-rpa` (default `develop`). PR title `[BT-XXXXX] ...`, bump `projectVersion`, no AI signature. There is no `gh` CLI: use the `githubgusto` MCP. TLS schannel error: `git -c http.sslBackend=openssl`.
- **Jira:** cloudId `gustohq.atlassian.net` (not `gusto.atlassian.net`). Project BT. Comments in English; closing comments simple and non-technical.
- **Buildkite:** pipeline `biztech-uipath-rpa`. Known intermittent failures: credentials share, analyzer race, Prod deploy 0x80131509 (Retry). A merged PR can still fail the `develop` build when a new check lands in between. See `06-learnings/feedback_buildkite_*` and `feedback_bots_only_gusto_dependencies_check_since_28oct`.
- **Slack:** `#biztech-automations-support` (automatic ticket to Jira), `#usp-rpa-benops-support-dev` (status to Sri, format in `feedback_sri_status_update_format`).
- **Bot tracking sheet:** `reference_benops_bots_tracking_sheet`.
- **Carrier portals (BSCA, BCBS, Kaiser, Anthem, UHC, Oxford, Beam, FloridaBlue):** per-ticket details in `04-process-history/`; selector pitfalls in `06-learnings/feedback_angular_*` and `feedback_scope_identifier_mismatch`.
