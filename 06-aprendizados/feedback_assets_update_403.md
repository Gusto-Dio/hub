---
name: feedback_assets_update_403
description: "uip orchestrator assets update retorna 403 Forbidden para assets Credential no Staging — a conta do uip login só tem leitura"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 93fdb1e7-15ee-40f8-9a27-a06e7b9e7d1c
---

`uip orchestrator assets update <key> "username:password" --type Credential` falha com `403 Forbidden` mesmo estando logado corretamente no tenant certo (Staging) e com o asset correto (`assets list`/`assets get` funcionam sem problema — é só leitura de metadados, não do valor).

**Why:** a conta/API client usada pelo `uip login` tem permissão de leitura (`Assets.View`) mas não de escrita (`Assets.Edit`) — bem provável que seja governança deliberada da Gusto pra impedir escrita/rotação de credenciais via API/automação.

**How to apply:** não insistir tentando outros formatos de valor ou flags — é permissão, não sintaxe. Passar o valor (username/password) pro usuário e pedir que ele mesmo atualize manualmente no Orchestrator UI (Assets > editar o Credential), informando o `--folder-path` e a `Key` (GUID) do asset pra ele achar rápido. Nunca tentar contornar isso com escalonamento de permissão sem pedir.

Related: [[feedback_getcredential_support]], [[feedback_local_debug_folder_binding]].
