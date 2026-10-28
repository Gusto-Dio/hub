# UiPath

- Cloud: https://cloud.uipath.com, org `gustoinc`.
- Tenants: **Staging** (the default after `uip login`) and **Production**. Never assume Production: run `uip login status` and confirm before pulling logs or publishing. Switch with `uip login tenant set <name>` and go back to Staging when done.
- Orchestrator folder is not the repo path: see `06-learnings/reference_orchestrator_folder_vs_repo_path.md`. Example: the FloridaBlue_NewHireEnrollment Process lives in folder `Benefits`.
- CLI: `uip` 1.204.x. Reference: `06-learnings/uip_rpa_cli_reference.md`.
- Studio does not support rpa-tool (see `feedback_studio_rpa_tool_unsupported`).
- Deploy: Buildkite auto-deploys only Production and only publishes to the feed; it does not activate the Process. Rebind with `uip or processes update-version <ProcessKey GUID> --package-version X --folder-path <folder>` (needs explicit approval) and verify with `uip or processes list`. Staging is manual (`uip or libraries upload`). `uip libraries upload` is not `packages upload`.
- Pack: `uip rpa pack --package-id <name>`; if Helm needs .NET 10 use uipcli (`reference_pack_with_uipcli_when_helm_needs_dotnet10`).
- Queues: see `reference_uip_queue_items_cli_gotchas` and `feedback_uip_queue_items_get_repascalizes_keys`.
