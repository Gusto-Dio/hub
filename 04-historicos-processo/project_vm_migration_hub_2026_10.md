---
name: project-vm-migration-hub-2026-10
description: Migração da VDI Porto para VM AWS (27/10/2026) — hub de conhecimento em Gusto-Dio/hub; progresso do setup da VM nova
metadata:
  node_type: memory
  type: project
  originSessionId: 6bc790a4-5e22-4ad1-8185-2c04a80fb223
  modified: 2026-10-27T20:59:43.863Z
---

Dio está saindo da Porto VDI para uma VM AWS e quer levar o conhecimento do Claude junto.

**Hub criado e publicado (27/10/2026):** `U:\hub` → repo privado `https://github.com/Gusto-Dio/hub` (branch main, commit 8bd6707). Pastas: 01-credenciais (só mapa, sem valores), 02-plataformas, 03-ferramentas (comandos Claude + `scripts/restore-memory.ps1`), 04-historicos-processo, 05-historicos-sessao, 06-aprendizados, 07-requirements. Contém cópia das 134 memórias de hoje; se a memória mudar antes da migração, re-sincronizar e commitar. Falta salvar o script de transcript de vídeo em Python (ainda não existe).

**Progresso na VM nova (usuário diogenes.ribeiro, em outra tela) — atualizado 27/10 após o push do hub (commit 08dc92a):**
- FEITO e verificado em PowerShell novo: git 2.54.0, node 24.21.0, dotnet 8.0.421, Claude Code 2.1.311 (npm com `--allow-scripts=@anthropic-ai/claude-code`), Python 3.14.7 (`winget install --id Python.Python.3.14 --source winget`; só funcionou como Administrador, erro 1625 sem admin; instala por usuário em `%LOCALAPPDATA%\Programs\Python\Python314`). PATH do usuário já inclui Python, Scripts e `%APPDATA%\npm` (usar GetEnvironmentVariable("Path","User"), nunca `$env:Path`).
- FEITO também (27/10, saída colada pelo Dio): clones em `C:\Projects\hub` (commit 08dc92a, sem o c8e6ced ainda não pushado na VDI → `git pull` depois do push) e `C:\Projects\biztech-uipath-rpa` (3933 arquivos); o clone do hub pediu autenticação no navegador e funcionou.
- NÃO CONFIRMADO pelo Dio (passei os comandos, ele não reportou): `pip install pillow boto3` e `git config --global user.name/email` — checar com `python -m pip list` e `git config --global --list`.
- PENDENTE, nesta ordem: (1) `python -m pip install pillow boto3` (confirmar); (2) git identity (confirmar); (3) `git -C C:\Projects\hub pull` após o push da VDI; (4) copiar `hub\CLAUDE.md` para `~/.claude/CLAUDE.md`; (5) `hub\03-ferramentas\scripts\restore-memory.ps1 -ProjectPath C:\Projects\biztech-uipath-rpa`; (6) `claude` com login SSO dentro do repo; (7) `uip` (instalar/login, conferir org gustoinc e tenant); (8) rodar `benops-rpa-setup`; (9) reautenticar MCPs em `/mcp`; (10) pedir à TI o share `\\fs3-prd-aws.gustocorp.com\BizTech` (Locks/creds); (11) liberar pop-ups no Chrome e instalar extensão UiPath como Current User; (12) teste final: perguntar ao Claude da VM sobre BT-77065.

**Why:** a VDI Porto vai sumir (incluindo U:), então o histórico e as regras precisam estar fora dela.
**How to apply:** ao retomar, perguntar em que etapa da lista pendente o Dio parou; push para Gusto-Dio foi bloqueado pelo auto mode e o Dio rodou via `!`. Ver [[feedback_git_identity_not_configured]], [[feedback_python_vdi]].
