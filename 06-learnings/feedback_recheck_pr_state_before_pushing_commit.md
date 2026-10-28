---
name: feedback_recheck_pr_state_before_pushing_commit
description: "Re-checar estado da PR via API antes de dar push de commit novo numa branch \"aberta\" em sessões longas"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fcf76cb6-86d6-4ba8-bef8-335e2ec8d71e
  modified: 2026-09-17T10:17:09.649Z
---

Uma PR pode ser mergeada (pelo usuário, no GitHub) e sua branch remota deletada automaticamente enquanto o agente ainda está trabalhando na mesma tarefa. Se o agente der `git push origin local:nome-da-branch-antiga` sem re-checar, o git simplesmente CRIA uma branch nova com esse nome — sem religar à PR original (que já está closed/merged) — e o commit fica órfão, sem PR nenhuma associada.

**Why:** aconteceu em [[project_bt75792_bsca_navigatetoonlinerenewals_popup_fix]] — PR #3339 foi mergeada pelo usuário no meio da sessão (branch deletada), enquanto eu editava a lib para adicionar um commit de consolidação. `git ls-remote` não mostrou a branch (já tinha sido deletada), mas `git fetch origin <sha>` funcionou (commit ainda alcançável via develop), mascarando o problema até o push criar uma branch nova sem PR. Só percebi ao reconsultar `pull_request_read` e ver `"state":"closed","merged":true`.

**How to apply:** antes de commitar+pushar em uma branch de PR que foi lida no início da sessão (ou há mais de alguns minutos), rechecar `pull_request_read` (ou `git ls-remote origin '<branch>'`) pra confirmar que ainda está `open` e a branch remota ainda existe. Se a PR já foi mergeada, abrir uma PR nova em cima do que já está em `develop`, em vez de tentar reaproveitar o nome da branch antiga.
