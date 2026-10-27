---
name: project-vm-migration-hub-2026-10
description: Migração da VDI Porto para VM AWS (27/10/2026) — hub de conhecimento em Gusto-Dio/hub; progresso do setup da VM nova
metadata:
  node_type: memory
  type: project
  originSessionId: 6bc790a4-5e22-4ad1-8185-2c04a80fb223
  modified: 2026-10-27T20:24:03.653Z
---

Dio está saindo da Porto VDI para uma VM AWS e quer levar o conhecimento do Claude junto.

**Hub criado e publicado (27/10/2026):** `U:\hub` → repo privado `https://github.com/Gusto-Dio/hub` (branch main, commit 8bd6707). Pastas: 01-credenciais (só mapa, sem valores), 02-plataformas, 03-ferramentas (comandos Claude + `scripts/restore-memory.ps1`), 04-historicos-processo, 05-historicos-sessao, 06-aprendizados, 07-requirements. Contém cópia das 134 memórias de hoje; se a memória mudar antes da migração, re-sincronizar e commitar. Falta salvar o script de transcript de vídeo em Python (ainda não existe).

**Progresso na VM nova (usuário diogenes.ribeiro, em outra tela):**
- Já tinha: git 2.54.0, node 24.21.0, dotnet 8.0.421.
- Claude Code 2.1.311 instalado via npm (`npm install -g --allow-scripts=@anthropic-ai/claude-code @anthropic-ai/claude-code`); `claude` só funcionava pelo caminho completo `%APPDATA%\npm\claude.cmd` até o PATH do usuário ser ajustado.
- Python 3.14.7 instalado via `winget install --id Python.Python.3.14 --source winget`; no PowerShell comum deu erro 1625 ("Organization policies"), mas rodando como Administrador funcionou. Instalou por usuário em `%LOCALAPPDATA%\Programs\Python\Python314`, fora do PATH — precisa adicionar essa pasta + `\Scripts` + `%APPDATA%\npm` ao PATH do usuário (usar GetEnvironmentVariable("Path","User"), não `$env:Path`).
- Pendente: confirmar `python`/`claude --version` em shell novo, `pip install pillow boto3`, git identity (Diogenes Ribeiro / diogenes.ribeiro@gusto.com), clonar `Gusto-Dio/hub` e `Gusto/biztech-uipath-rpa`, copiar `CLAUDE.md` para `~/.claude/CLAUDE.md`, rodar `restore-memory.ps1 -ProjectPath <pasta do repo>`, `uip login`, reautenticar MCPs em `/mcp`, rodar `benops-rpa-setup`, pedir à TI acesso ao share `\\fs3-prd-aws.gustocorp.com\BizTech` e liberar pop-ups no Chrome.

**Why:** a VDI Porto vai sumir (incluindo U:), então o histórico e as regras precisam estar fora dela.
**How to apply:** ao retomar, perguntar em que etapa da lista pendente o Dio parou; push para Gusto-Dio foi bloqueado pelo auto mode e o Dio rodou via `!`. Ver [[feedback_git_identity_not_configured]], [[feedback_python_vdi]].
