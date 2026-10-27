# Outras plataformas

- **GitHub:** repo `Gusto/biztech-uipath-rpa` (default `develop`). PRs com título `[BT-XXXXX] ...`, bumpar `projectVersion`, sem assinatura de IA. Se `gh` não existir, usar o MCP `githubgusto`. TLS schannel: `git -c http.sslBackend=openssl`.
- **Jira:** cloudId `gustohq.atlassian.net` (não `gusto.atlassian.net`). Projeto BT. Comentários em inglês; no fechamento, texto simples e não técnico.
- **Buildkite:** pipeline `biztech-uipath-rpa`. Falhas intermitentes conhecidas: share de credenciais, analyzer race, deploy Prod 0x80131509 (Retry). Ver `06-aprendizados/feedback_buildkite_*`.
- **Slack:** `#biztech-automations-support` (chamado automático → Jira), `#usp-rpa-benops-support-dev` (status ao Sri, formato em `feedback_sri_status_update_format`).
- **Planilha de acompanhamento dos bots:** `reference_benops_bots_tracking_sheet`.
- **Portais de operadoras (BSCA, BCBS, Kaiser, Anthem, UHC, Oxford, Beam, FloridaBlue):** detalhes por ticket em `04-historicos-processo/`; armadilhas de seletor em `06-aprendizados/feedback_angular_*`, `feedback_scope_identifier_mismatch`.
