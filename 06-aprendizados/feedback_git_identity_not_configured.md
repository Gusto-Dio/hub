---
name: feedback_git_identity_not_configured
description: VDI nunca teve git config user.name/user.email setado; commits saem com autoria auto-gerada gustocloud.apporto
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5b40cb84-a7b2-4e5b-bf69-81bb3fc1d216
  modified: 2026-08-19T12:37:26.993Z
---

Um commit criado nesta VDI (Apporto) saiu com autoria auto-gerada pelo Git a partir do
hostname — `diogenesribei_gsto <diogenesribei_gsto@gustocloud.apporto>` — em vez do email real
do usuário. `git config user.name`/`user.email` nunca tinham sido configurados globalmente
nessa máquina. Todos os outros commits do repo usam nome/email reais (`@gusto.com`).

**Why:** VDIs novas (Apporto) não vêm com identidade Git pré-configurada; o Git cai pro fallback
automático baseado em username+hostname, que não corresponde à identidade real do usuário
(Diogenes Ribeiro, diogenes.ribeiro@gusto.com) nem bate com o padrão do resto do time.

**How to apply:** antes do primeiro commit em uma VDI nova, rodar `git config --global user.name`
e `user.email` (checar se já estão setados com `git config user.name`/`user.email` antes). Se um
commit já foi criado com a identidade errada e ainda não foi pushado, corrigir com
`git commit --amend --reset-author` depois de configurar. Perguntar ao usuário antes de mudar o
git config, já que isso é tecnicamente uma ação de configuração global (ver regra "nunca
atualizar git config" nas instruções do projeto) — mas nesse caso o usuário confirmou que queria
o fix global + amend. Ver [[project_bt74936_anthem_memberupdates_navigate_er]] onde isso foi
descoberto.
