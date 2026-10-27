# Hub do Dio — BizTech/BenOps RPA (Gusto)

Este CLAUDE.md vai em `~/.claude/CLAUDE.md` na máquina nova. Ele diz ao Claude quem eu sou, como trabalho e onde está o conhecimento acumulado.

## Quem sou
- Diogenes Ribeiro (Dio), diogenes.ribeiro@gusto.com, time BizTech / BenOps RPA, Gusto.
- Trabalho em UiPath RPA (Studio, Orchestrator, `uip` CLI) no repo `Gusto/biztech-uipath-rpa`. Branch padrão: `develop`.
- Converso em português. **Jira comments e PR bodies sempre em inglês.**

## Onde está o conhecimento
Tudo em `hub/` (este repositório). Leia o que for relevante antes de agir:
- `01-credenciais/`: ONDE ficam credenciais e como obtê-las. Nunca valores.
- `02-plataformas/`: UiPath, Buildkite, GitHub, Jira, Slack, portais de operadoras.
- `03-ferramentas/`: scripts, comandos Claude, atalhos.
- `04-historicos-processo/`: um arquivo por ticket/processo (project_*.md).
- `05-historicos-sessao/`: `work_state.md` e o índice `MEMORY.md`.
- `06-aprendizados/`: regras e armadilhas (feedback_*.md, reference_*.md, uip_rpa_cli_reference.md).
- `07-requirements/`: versões e script de instalação do ambiente.

Os arquivos de memória têm frontmatter (`name`, `description`, `metadata.type`). `05-historicos-sessao/MEMORY.md` é o índice; consulte-o primeiro e abra só o que precisar.

## Regras permanentes (resumo; detalhes em 06-aprendizados)
- **Segurança (política da empresa):** dado de empresa nunca sai para destino pessoal/público. Nada de segredos nem PII real em arquivos versionados. Local é livre; push/compartilhamento exige confirmar o destino.
- PRs: sem assinatura/co-author de IA, texto simples sem tabela (`feedback_pr_no_claude_signature_no_tx_table`).
- `uip`: rodar `uip login status` antes de mexer em tenant (o default não é Production). Testes sempre via `uip or jobs start`.
- `uip rpa pack`: conferir `git branch --show-current` e passar `--package-id` explícito.
- `dependencylock.json` estrito: todo projeto alterado = lock exato; bumpar `projectVersion` em todo PR.
- Production: leitura e escrita pedem aprovação explícita; Buildkite só auto-deploya Production (Staging é manual) e só publica no feed, sem ativar o Process.
- Antes de editar processo "irmão" parecido, conferir o GUID do projeto.

## Primeira sessão na máquina nova
Execute `07-requirements/README.md` (instalação) e depois `01-credenciais/README.md` (logins). Para restaurar a memória: `03-ferramentas/scripts/restore-memory.ps1`.
