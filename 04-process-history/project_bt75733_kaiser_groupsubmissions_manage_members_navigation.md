---
name: project_bt75733_kaiser_groupsubmissions_manage_members_navigation
description: "BT-75733 - TICKET FECHADO (2026-09-16) - dois root causes corrigidos: navegacao pos-delegate-account, e busca por Group ID via InteractionMode=Simulate que nao disparava eventos de teclado do Angular. PR #3338 merged, deployado em Staging e Production."
metadata: 
  node_type: memory
  type: project
  originSessionId: d4a8b26a-3d0b-4cfb-b25d-ae75fb39e01b
  modified: 2026-09-16T20:56:22.422Z
---

**Ticket:** BT-75733 (reporter Bri Boyer, Medium/High). Impactado: `Kaiser_GroupSubmissions_MemberLevel_Modern`. Sintoma original: "Bot is faulting for 3+ days... getting the broker dashboard and then is not moving past that page." 40 casos na fila. Aberto via `#biztech-automations-support`.

**Branch:** `BT-75733-Kaiser-GroupSubmissions-MemberLevel-manage-members-navigation`, criada a partir do `develop` atualizado. Nada commitado ainda.

## Root cause #1 (confirmado e corrigido) — navegação quebrada

`BT-75495` (migração pra delegate account, mergeada 2026-09-11) removeu a chamada a `NavigateToBookOfBusiness.xaml` do `InitEnvironment.xaml`, assumindo (errado) que o `SearchForGroup.xaml` já navegava até "Manage Members" sozinho. Na verdade `SearchForGroup.xaml`'s `NApplicationCard_1` só **anexa** (`OpenMode="Never"`, título exato "Manage Members - Kaiser Permanente") — nunca navegou. Depois do `SwitchToDelegatedAccount`, o navegador fica em "Client Overview", não em "Manage Members" — daí o `ApplicationNotFoundException` (closest match 83% "Client Overview").

Confirmado pelo histórico de jobs em Produção: sucesso todo dia 09-01 a 09-10, falha em TODO run desde 09-11 (dia do merge do BT-75495).

**Fix aplicado em `ProcessLayer/SearchForGroup.xaml`** (dentro do `NApplicationCard_1`):
- `TargetApp` ampliado pra wildcard `*Kaiser Permanente` (aceita "Client Overview" e qualquer outra tela)
- Restaurado o `NCheckState` "If In A Group & Need to Switch" (tinha sido removido numa iteração anterior por engano)
- No branch `IfNotExists` (antes vazio — só fazia sentido quando `NavigateToBookOfBusiness` já tinha rodado no Init) agora tem 2 cliques novos: **'Book of Business'** (`id='nav-0-menu-item-link-1'`) → **'Manage Members'** (`id='manage-members'`) — usa o menu superior global do portal, IDs reais capturados de um HTML salvo ao vivo
- Tentativa descartada: um `NGoToUrl` direto pra `managemembers#/groups/subgroups?groupid={in_GroupNumber}&region=CAL&delegator=MHWithGusto1` — a navegação funcionou (redirecionou certo pro domínio legado `account.kp.org/EBSS/ebssp#/groups`), mas caiu num formato de página group-specific que não bate com a lógica de busca existente. Ficou comentado (`ui:CommentOut`) até ser substituído pelo fix atual.

**Confirmado ao vivo (2026-09-16):** a navegação Book of Business → Manage Members funciona sem erro agora — usuário validou visualmente.

## Root cause #2 (NÃO confirmado, aberto) — "Group not in carrier portal"

Depois do fix de navegação, TODOS os grupos reais testados (10 diferentes, puxados de itens `New` reais em Produção: 361872, 367034, 735488, 735525, 740496, 721640, 364386, 730306, 737815, 737870) falham igual, na busca por Group ID dentro do `NApplicationCard_2` (código original, nunca alterado por esse fix): `CarrierPortalException: Group not in carrier portal`.

**Descartado como causa:**
- Mecanismo de busca em si — confirmado funcionando: usuário rodou `Kaiser_CA_MemberUpdates` (processo idêntico, confirmado funcionando em Produção) ao vivo e viu a busca filtrar a lista pra uma linha só, pro grupo de teste dele (735270).
- `Type Into` sem `VerifyOptions` — adicionei `VerifyOptions Mode="Appears"` (faltava vs. o do MemberUpdates); usuário também copiou o `Type Into` inteiro do MemberUpdates pro nosso processo. Mesmo assim, nenhum dos 2 ajustes resolveu — a busca continua não achando nenhum dos grupos testados.
- Especulação inicial (descartada sem prova, usuário corrigiu corretamente): não é Healing Agent — código idêntico ao `MemberUpdates` em ambos os processos, sem explicação viva confirmada de como o `MemberUpdates` chega em "Manage Members" sem navegação explícita no código (mistério não resolvido, mas irrelevante pro fix atual).

**Suspeita atual, forte:** é questão de DADO/portal, não bug de código — os 10 grupos reais testados podem genuinamente não estar visíveis pra esse delegate account no momento (book of business tem 4294 grupos "Small Business" + paginação).

**Precedente histórico relevante:** BT-68870 (dez/2025), mesma reporter (Bri Boyer), MESMO erro "Group not in carrier portal" nesse MESMO processo, ANTES de existir delegate account. Ela disse na época: "this looks like it may be a temporary portal issue... I have been able to search them without issue... I reviewed all the failed transactions for this from today and was able to find all of the groups in portal" e pediu pra trocar de business exception pra system exception (retry) em vez de falha dura após 3 seguidas. Ou seja, esse erro específico JÁ tinha histórico de ser intermitente/portal-side antes da regressão de navegação atual.

**Resposta da Bri (2026-09-16, 11:13):** confirmou 5 grupos que ela mesma verificou manualmente no portal agora: 735549 (a0mR700000HRzSDIA1), 740671 (a0mR700000HNAZZIA5), 364242 (a0mR700000HjFh3IAF), 735419 (a0mR700000HqXZDIA3), 732998 (a0mR700000HZNw1IAH).

## Root cause #2 (CONFIRMADO e corrigido) — `InteractionMode="Simulate"` no card de busca

`SearchForGroup.xaml`, `NApplicationCard_2` (o card que digita no campo de busca "Manage Members") usava `InteractionMode="Simulate"` — esse modo escreve o texto inteiro de uma vez, sem disparar os eventos `keyup`/`input` por caractere que o filtro Angular da tabela de resultados escuta. O campo recebia o valor mas a tabela nunca re-filtrava, então TODO grupo (mesmo existindo) dava "Group not in carrier portal" — indistinguível de dado/portal ruim até o usuário notar que digitando manualmente, char a char, o grupo aparecia.

Mais adiante no mesmo arquivo (`NApplicationCard_3`), o código já usa `InteractionMode="DebuggerApi"` pra outra verificação na mesma tabela Angular — precedente direto de que esse modo funciona nesse componente.

**Fix:** trocado `InteractionMode="Simulate"` → `InteractionMode="DebuggerApi"` no `NApplicationCard_2`. Ver [[feedback_angular_typeinto_simulate_mode_no_events]].

## Armadilha grave durante o teste: dado sintético invalidou a primeira rodada

Pra testar, recriei os itens de fila no Staging usando `Group_Number__c` e `Id` reais (dos 5 confirmados pela Bri), mas **copiei os outros campos** (`ZP_Company_Id__c`, `Application_Id__c`, `Benefit_Order__c`, etc.) de um item de teste antigo e não relacionado (grupo 721640). Isso quase gerou uma conclusão errada: a busca funcionou (achou o grupo), mas o census baixado do S3 era de uma empresa diferente, e bateu erro de negócio "Census policies do not match" — parecendo um bug quando não era. Usuário corrigiu a tempo: "não podemos, tem que ser os mesmos dados do item original, podemos comentar conclusões incorretas". Ver [[feedback_test_data_must_be_real_not_borrowed]].

**Solução:** os 5 Carrier_Order__c reais já estavam parados como itens `New` na fila real de **Production** (mesmos que a Bri linkou) — puxei o `SpecificData` de lá (via `uip login tenant set Production`, leitura bloqueada uma vez pelo classificador de auto mode até o usuário aprovar) e recriei os itens no Staging com os dados 100% reais.

## Resultado final do teste com dado real

`SearchForGroup was successful` pra todos os grupos testados. As exceções de negócio que sobraram ("Order is no longer in Automation Queue") foram rastreadas a efeito colateral dos próprios testes anteriores — o `UpdateCarrierOrder.xaml` escreve de volta no Salesforce real mesmo no caminho de exceção, então rodar o mesmo Carrier_Order__c real repetidas vezes em testes consome sua elegibilidade real de automação. Não é bug do fix.

## Deploy

- PR #3338 (`develop`) — 4 arquivos: `Main.xaml`, `ProcessLayer/SearchForGroup.xaml`, `project.json` (bump `1.6.4`→`1.6.5`), `entry-points.json` (recriado, tinha sido apagado do disco por uma tentativa de pack via `uipcli`). Aprovada e merged 2026-09-16.
- Publicado e **ativado** (`processes update-version`) em Staging e Production, ambos confirmados em `1.6.5` / `IsLatestVersion: true`.
- Antes do deploy, `uip rpa pack` falhou com `ST-SEC-008 (Error)` — mas é falso positivo da ferramenta local; instalei o `uipcli` real (UiPath.CLI.Windows 25.10.16, mesma versão do `deploy.ps1`) e confirmei que builda limpo (mesmo warning, mas não Error) e que já é pré-existente em `develop`. Ver [[feedback_uip_rpa_pack_vs_real_uipcli_analyzer_severity]].
- **TICKET FECHADO.** Mensagem final pra Bri via rascunho no Slack (thread `#biztech-automations-support`, ts `1789488167.784719`).

**Próximo ticket assumido:** BT-75792 — `BSCA_GroupSubmissions_GroupLevel` e `BSCA_GroupSubmissions_MemberLevel`, ambos faltando 3+ dias sem processar nenhuma ordem, Medium priority, status "Under investigation".
