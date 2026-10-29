# Production and `uip`

## Tenant discipline
- Run `uip login status` before touching any tenant. The saved default is Staging; never assume it, and never assume it is Production.
- For a Production action: `uip login tenant set Production`, do the action, re-read to verify, then `uip login tenant set Staging` again.
- Check `organizationUnitId` in the job log before trusting a Studio debug run: the Studio robot connection can point at another tenant than the CLI (`feedback_studio_robot_connection_can_diverge_from_uip_cli_tenant`).
- A "jobs list is empty" result can just be the wrong folder: the Orchestrator folder is not the repo path (`reference_orchestrator_folder_vs_repo_path`).

## Approvals
Reads and writes in Production need explicit approval from Dio each time; the auto mode blocks even a plain GET. Also explicit approval for: Process rebind (Production and Staging), disabling or enabling triggers, scheduled tasks, deleting queue items (`--yes`), asset writes, anything in the Orchestrator that changes live behavior.
- Disabling a trigger: check the real cron (`StartProcessCron`) before calling a trigger dead; a gap of days is not evidence (`feedback_check_cron_before_flagging_stuck_trigger`).
- Credential asset writes via `uip` return 403; they are manual in the Orchestrator UI (`feedback_assets_update_403`).
- Deleting a queue item and recreating it: the CLI re-serializes `SpecificContent` in PascalCase, so compare against the real JSON schema before recreating (`feedback_uip_queue_items_get_repascalizes_keys`, `reference_uip_queue_items_cli_gotchas`).

## Production safety
- Do not widen the `BusinessRuleException` gate in ProcessTransaction: it exists so a retry happens before the Salesforce Owner is burned (`feedback_businessruleexception_gate_is_intentional`, `feedback_salesforce_owner_burn_guard`).
- A login circuit breaker file in the Locks share explains "invalid credentials" that are not really credentials (`reference_login_circuit_breaker_locks_share`). Check it before blaming the credential.
- Never trigger a Production process just to "test"; use a Staging queue with a real Production item copied there.
- When reporting Production state, quote the version actually bound to the Process (`ProcessVersion`), not the feed version.

## `uip` facts worth remembering
- Queue test items: `uip or jobs start` after creating items in the Staging queue.
- `uip rpa pack`: always `--package-id`, always a branch check (see `git-and-pr.md`).
- JSON arguments: write a BOM-free temp file instead of word-splitting (`feedback_uip_cli_json`).
- Credential assets can be read for debug through a helper XAML with `GetRobotCredential`, but a headless `uip rpa run` fails on the folder binding (`feedback_getcredential_support`, `feedback_local_debug_folder_binding`).
- Full reference: `../06-learnings/uip_rpa_cli_reference.md`.
