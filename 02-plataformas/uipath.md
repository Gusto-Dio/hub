# UiPath

- Cloud: https://cloud.uipath.com — org `gustoinc`.
- Tenants: **Production** (default do login atual) e **Staging**. O default NÃO é garantidamente Production: rode `uip login status` e confirme antes de logs/publicações.
- Folder do Orchestrator ≠ caminho do repo: ver `06-aprendizados/reference_orchestrator_folder_vs_repo_path.md`.
- CLI: `uip` 1.204.0 (plugin Claude `uipath@uipath-marketplace` 1.204.1). Referência: `06-aprendizados/uip_rpa_cli_reference.md`.
- Studio na VDI: sem suporte a rpa-tool (ver `feedback_studio_rpa_tool_unsupported`).
- Deploy: Buildkite autodeploya só Production; Staging é manual (`uip or libraries upload`). `uip libraries upload` ≠ `packages upload`.
- Pack: `uip rpa pack --package-id <name>`; se Helm exigir .NET 10 usar uipcli (`reference_pack_with_uipcli_when_helm_needs_dotnet10`).
- Filas: ver `reference_uip_queue_items_cli_gotchas` e `feedback_uip_queue_items_get_repascalizes_keys`.
