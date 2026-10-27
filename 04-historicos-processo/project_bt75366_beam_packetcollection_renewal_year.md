---
name: project_bt75366_beam_packetcollection_renewal_year
description: "BT-75366 tem duas frentes sob o mesmo número — fix de lib (NullReferenceException, PR #3283 mergeada) e fix do processo Beam (12/1 renewal packets travados, PR #3284 aberta)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9c59feb3-854e-4d81-a282-af0f80c03404
  modified: 2026-09-03T03:05:17.212Z
---

**BT-75366** originalmente é sobre `Advising_Beam_PacketCollection` não coletando pacotes de renovação 12/1 disponíveis (~290+ pacotes, ~5% do automation rate) — bot reporta `"An exception has occurred: Waiting for Packet"` mesmo com o pacote já disponível no portal Beam.

## Frente 1 — Library fix (branch dedicada, reusando o número do ticket)
- Durante a investigação inicial (log de Studio vs Prod), achamos um bug SEPARADO e não relacionado no upload pro Salesforce: `NullReferenceException` em `Libraries/Gusto_Generic_SalesForce/UploadFile.xaml` quando a autenticação SFDC falha em todas as tentativas de retry — `contentStatus` fica `Nothing` (a activity nativa de upload nunca roda), e `NOT contentStatus.Success` explode antes do guard de `SystemError` (VB `OrElse` NÃO faz short-circuit quando o operando esquerdo é `False`).
- Fix: null guards em `contentStatus`/`attachmentStatus` (Transition_10 "Abort", Transition_14 "Success", If_17/If_18 do estado final) + reordenar o check de `SystemError` pra rodar primeiro. Branch `BT-75366-Gusto-Generic-SalesForce-UploadFile-nullref-fix`.
- **Achado importante:** existe uma versão `2.0.0` publicada no feed de **Production** sem NENHUM commit correspondente em todo o histórico git — órfã, provavelmente publicação de teste do Ahsen (autor: ahsen.turksoy, mesma data que a 1.10.0 real) que nunca foi limpa. `check_version.sh` compara contra a versão mais alta JÁ publicada em Prod (não a que está efetivamente em uso via `Gusto_Benefits`), então nosso `1.10.1` foi rejeitado como downgrade (`"process can't be upgraded from version 2.0.0 to 1.10.1"`). Resolvido bumpando pra `2.0.1` (mesmo código/fix, só o número saltado pra passar do órfão) — decisão do usuário: pular a versão em vez de investigar o 2.0.0 antes.
- **PR #3283 — MERGEADA ✅** em develop: https://github.com/Gusto/biztech-uipath-rpa/pull/3283
- **Pendência não bloqueante:** avisar o Ahsen sobre o `2.0.0` órfão no feed de Production, pra não confundir o próximo bump dessa lib.

## Frente 2 — Fix real do ticket (branch `BT-75366-Advising-Beam-PacketCollection-renewal-year-gate`)
- Mecanismo em `CollectPacket.xaml`: `portalRenewalDate = In_RenewalDate.Year.ToString` → clica "Renewals" → `UiElementExists` ("Element Exists 'Renewal Year'") procura uma `DIV` com `innertext` igual ao ano → se achar, `renewalAvailable=True` e baixa o pacote; se não achar, cai em `CheckCollectionFirstAttemptDate` que lança `"Waiting for Packet"` — exceção que o catch de `ProcessTransaction.xaml` trata como sucesso silencioso (`SetTransactionStatus Status="Successful"`), mascarando a falha real (bot "sucede" sem nunca ter coletado nada).
- Hipótese inicial (mismatch de rótulo de ano no portal pra renovações 12/1) foi DESCARTADA: reproduzindo os 2 itens reais do ticket em Staging — MindDemand (TX25346) e Barton Mendez Soto PLLC (AZ01280), ambos com `RenewalDate=12/1/2026`, ambos já com `Status=Successful` em Prod sem terem coletado nada — `portalRenewalDate` calculou `"2026"` corretamente e `renewalAvailable=True` bateu certo, achou o elemento sem problema.
- Hipótese atual (não 100% confirmada por evidência de log histórico, mas é o fix aplicado a pedido do usuário): **timing/race condition** — `UiElementExists` tem `TimeoutMS=20000` hardcoded sem retry; em dias de pico (início de temporada 12/1, muita gente acessando o portal Beam ao mesmo tempo), o card do ano pode demorar mais que isso pra renderizar, dando falso negativo pontual. Usuário: "acho que pode ser que em prod tenha que ter um pouco mais de cadência entre uma transação e outra".
- **Fix aplicado:** `DelayMS=2000` nos `Click 'Renewals'` e `Click 'Get Renewal Letter'` (adicionado pelo usuário direto no Studio) + 4 `ui:LogMessage` (Level=Info) de trace depois de cada ação chave (Click Renewals, Element Exists Renewal Year, Click Get Renewal Letter, SavePacket) — `LogMessage_4` a `LogMessage_7` em `CollectPacket.xaml` — pra dar visibilidade de timing em execuções futuras via job logs.
- **Comunicação externa (Jira):** a pedido explícito do usuário, o comentário no ticket e a PR NÃO mencionam a palavra "delay" — só "resilience improvements"/"pacing adjustments".
- **Validado em Staging:** os 2 itens reais (recriados na fila `Beam_Packets` com o `SpecificData` exato de Produção, snake_case: `group_name`, `carrier_name`, etc.) rodaram com sucesso end-to-end — pacote coletado.
- **PR #3284 — ABERTA ✅** https://github.com/Gusto/biztech-uipath-rpa/pull/3284
- Comentário postado no Jira BT-75366 confirmando reprocessamento bem-sucedido dos 2 grupos.
- Pra abrir a PR foi necessário: merge do `develop` (trouxe o PR #3283 já mergeado + vários bumps do Anthem não relacionados), resolver conflito no `dependencylock.json` raiz (tomando a versão do develop), e sincronizar `Gusto_Benefits` (1.557.1→1.559.10) e `projectVersion` (2.11.2→2.11.3) no `project.json` do Beam pra não quebrar `check_dependency.sh`/`check_version.sh`.

## Técnica reutilizável
Pra achar um queue item de Produção a partir só do Id numérico visível na URL do Orchestrator (`.../queues/<qid>/transactions(sidepanel:sidepanel/transactions/<id>/details)?tid=...&fid=...`): `uip or queue-items get` exige GUID (`uniqueKey`), NÃO aceita o Id numérico da URL (dá 404). Resolver via `uip or queue-items list --sort-by "Id desc" --limit 100 --offset N --output-filter "[?Id==\`<id>\`]"`, paginando em incrementos de 100 até achar (o Id é sequencial cross-tenant, não por fila).

Ver também [[feedback_library_version_collision_staging_prod]], [[feedback_shared_root_dependencylock_conflicts]], [[feedback_check_version_bump_before_pr]], [[feedback_staging_queue_items]].
