---
name: feedback_no_worktree_stay_in_original_repo
description: "Nao criar git worktree para um ticket: trabalhar no clone original, na branch do ticket; se ha trabalho de outra branch sujo, commitar localmente nela antes de trocar"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 09615167-e13b-4ade-9fd7-f65fddc2b3d0
  modified: 2026-10-30T02:44:53.233Z
---

Dio disse (30/10, BT-77264): o worktree separado "nao era a abordagem"; quer ficar dentro do repo original, na branch criada pro ticket. Eu tinha criado um worktree (`C:\Projects\biztech-uipath-rpa-BT-77264`) sem ele escolher, porque o clone principal estava na `BBO-3937` com 3 `slo.yaml` modificados.

**Why:** o Studio dele passou a editar no worktree, tive que salvar arquivos, remover o worktree e mover tudo de volta. Alem disso o `uip rpa validate` abriu um host headless (`UiPath.Studio.Helm`) que travou arquivos da pasta (`.local\.jit\cache\*.dll`) e o `git worktree remove` falhou com "Invalid argument"; so apagou depois de encerrar esse processo.

**How to apply:**
1. Nunca criar worktree sem o Dio pedir. Se o clone esta sujo em outra branch, PERGUNTAR as opcoes: commitar localmente na branch dele (so os arquivos certos, sem push), ou `git stash`; foi o que ele escolheu: "salve o que ja fizemos na branch dele, depois volta para a branch do ticket".
2. Antes do commit local em outra branch, ler o diff para garantir que e so numeros/config sem segredo nem PII; mensagem em ingles, sem assinatura de IA.
3. Se uma pasta travar na remocao, ver quem segura a DLL (`Get-Process ... Modules`) antes de forcar; o host Helm iniciado por `uip rpa` pode ser encerrado, ele reabre na proxima chamada.
4. Branch criada com `git branch --no-track <nome> origin/develop` nao muda o checkout; o nome deve ganhar o `BT-XXXXX` quando o bot do Slack criar o ticket (`git branch -m`).

Relacionado: [[project_bt77264_bsca_nhe_active_class_not_available]].
