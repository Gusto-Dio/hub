# hub

Base de conhecimento portável do Dio para trabalhar com Claude Code. Pensado para trocar de VDI/VM sem recomeçar do zero.

| Pasta | Conteúdo |
|---|---|
| 01-credenciais | onde estão e como recuperar credenciais (sem valores) |
| 02-plataformas | UiPath, Buildkite, GitHub, Jira, Slack, carriers |
| 03-ferramentas | comandos Claude, scripts, ferramentas do repo |
| 04-historicos-processo | histórico por ticket/processo |
| 05-historicos-sessao | work_state e índice de memória |
| 06-aprendizados | regras, armadilhas, referências |
| 07-requirements | versões e instalação do ambiente |

## Como usar na VM nova
1. `git clone` deste repo (a URL fica no destino que o Dio escolher).
2. Instale o Claude Code e abra `claude` dentro da pasta clonada.
3. Diga: "Leia CLAUDE.md e 07-requirements/README.md, instale o que falta e depois restaure a memória."
4. Copie `CLAUDE.md` para `~/.claude/CLAUDE.md`.

## Regra de ouro
Nada de segredo aqui. Senhas, tokens, `.credentials.json`, `~/.uipath/.auth` e `.env` nunca entram neste repo. Veja `01-credenciais`.
