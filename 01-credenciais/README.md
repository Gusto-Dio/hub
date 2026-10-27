# Credenciais — onde estão (NUNCA os valores)

Política: nenhum segredo neste repo. Aqui só há o mapa de onde cada coisa vive e como refazer o acesso na máquina nova.

| Acesso | Onde vive de verdade | Como refazer na VM nova |
|---|---|---|
| UiPath CLI (`uip`) | login interativo salvo em `~/.uipath/.auth` (não copiar) | `uip login` (org `gustoinc`, tenant `Production`; ver `02-plataformas/uipath.md`) |
| Assets Credential do Orchestrator (Credential_BSCA etc.) | Orchestrator, por folder; leitura via `GetRobotCredential` | nada a copiar; o robô lê direto |
| Claude Code | `~/.claude/.credentials.json` (não copiar) | `claude` → login SSO |
| GitHub | token/SSO da conta Gusto | `gh`/git credential manager, SSO da org Gusto |
| Jira/Confluence, Slack, Buildkite, Gmail, Sheets | conectores MCP do Claude (claude.ai) | autenticar de novo em `/mcp` |
| Cofre de MFA/SMS dos carriers | Google Voice → Gmail (ver `feedback_*`/`project_bt76628*`) | acesso via conta Gusto |
| Chave de service account Google (QueueBuilder) | asset no Orchestrator | nada a copiar |
| Compartilhamentos de rede (Z: BizTech, locks, creds) | `\fs3-prd-aws.gustocorp.com\BizTech` | ver `07-requirements/network-drives.md` |

## Não copiar para o repo
`~/.claude/.credentials.json`, `~/.uipath/.auth`, `~/.uipath/*`, `.env`, `.env.local`, qualquer `*.pfx/*.key`.

## Dica
Se algo falhar com "invalid credentials", antes de suspeitar do código veja o circuit breaker em `06-aprendizados/reference_login_circuit_breaker_locks_share.md`.
