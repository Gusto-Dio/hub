---
name: project-bt74936-anthem-memberupdates-navigate-er
description: "BT-74936 Anthem_MemberUpdates UnableToNavigateException (EmployerAccess Portal) — causa raiz original ainda sem fix; PR #3156 aberta corrigindo 2 problemas novos (popup de feedback + erro de zip code)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0b0cd63f-dc8c-4b74-b71c-c8748b9d5f3d
  modified: 2026-08-19T12:36:59.517Z
---

BT-74936 (Sri, Prioridade Medium) — `Anthem_MemberUpdates` falhando em Produção com
`UnableToNavigateException: Unable to navigate to EmployerAccess Portal`, quase toda
transação, 3 dias seguidos (10, 11, 12/08/2026). Investigado 2026-08-13, ainda sem PR.

Causa raiz isolada: `Libraries/Gusto_Benefits/Anthem/Generic/BrokerPortal/SearchForGroup.xaml`
— `Throw "UnableToNavigateException"` quando `groupLoaded` (setado por `UiElementExists` no
seletor `<html app='chrome.exe' title='Employer Access' /><webctrl aaname='{GroupNumber}*' />`)
continua False após 3 tentativas (90s/120s/150s). Arquivo não é tocado desde a migração
Legacy→Modern (#2518).

**Why:** faz parte da mesma sequência de quebras do redesign do portal broker da Anthem que
já gerou 3 fixes recentes na mesma library — 1.555.1 (`LoginToAnthemBroker`, #3007), 1.556.0
(seletor do "Sign in", #3040), 1.557.0 (`NavigateToGroupSearch`, #3052). `Anthem_MemberUpdates`
já está na 1.557.0 (mais atual) — login e busca de grupo já corrigidos; o erro deste ticket
acontece um passo DEPOIS (clicar pra abrir o ER Access do grupo), etapa nunca atualizada.
Erro secundário observado nos mesmos jobs (`TakeFullPageScreenshot` não acha diálogo "Save As")
parece não relacionado — não misturar no mesmo fix sem confirmar.

**How to apply:** é arquivo de Library (`Gusto_Benefits`), compartilhado por outros processos
Anthem — seguir o mesmo padrão dos 3 fixes anteriores: corrigir o seletor na library após
inspeção AO VIVO do portal Anthem Employer Access (não dá pra advinhar o seletor novo), depois
PR de bump de versão em cada processo consumidor. Ticket NÃO estava na planilha de tracking
(RPA BenOps Nov 2025 — registros param perto do BT-72959); Status/Dev Start Date não foram
atualizados lá, precisa adicionar manualmente. Ver [[project_bt74849_beam_nhe_portal_fix]] pra
padrão de fix parecido (portal redesign quebrando seletor).

**Confirmado (2026-08-14):** o arquivo certo é mesmo `Anthem/Generic/BrokerPortal/SearchForGroup.xaml`
(não `Anthem/Generic/ERAccessPortal/SearchForGroup.xaml`, que também existe na mesma library) —
confirmado pelo namespace usado no `InitAllApplications.xaml` do `Anthem_MemberUpdates`
(`xmlns:gagb="clr-namespace:Gusto_Benefits.Anthem.Generic.BrokerPortal"`, usado tanto no
`NavigateToGroupSearch` quanto no `LoginToAnthemBroker`).

**Branch criada:** `BT-74936-Anthem-MemberUpdates-navigate-er-fix`, a partir de `develop`
atualizado (2026-08-14).

**Bloqueio de infra (2026-08-14, ver [[feedback_vdi_missing_locks_share_access]]):** debug ao
vivo no Studio travou ANTES de chegar no erro real — a activity `AcquireLoginLock` (login lock
serializado entre bots Anthem, "traffic light" segundo o Oscar) falha porque a VDI não tem
acesso a `\\usscl1-fs-3\BizTech\RPA\Locks`. Confirmado com Oscar via DM Slack; usuário vai pedir
acesso ao path via Apporto/IT. Debug do erro real (`UnableToNavigateException` no Employer
Access) fica pausado até esse acesso ser concedido.

**Workaround local (2026-08-18):** branch tem `config.json` alterado — `LocksFolderPath` de
`\\usscl1-fs-3\BizTech\RPA\Locks` pra `Z:\Locks`, e `ExScreenshotsFolderPath` de
`\\usscl1-fs-3\BizTech\ExceptionScreenshots` pra `Y:\ExceptionScreenshots` — drives mapeados só
na VDI do usuário via Apporto. **NÃO pode ir pro PR/commit** — robô no Orchestrator não tem
esses drives, ia quebrar em produção. É só pra destravar o `AcquireLoginLock` localmente e
conseguir debugar. Reverter antes de commitar qualquer fix real.

**Teste em Staging passou limpo (2026-08-18):** rodou 1 item na Staging com o workaround acima
e não caiu no `UnableToNavigateException`. Hipótese mais provável: antes o `AcquireLoginLock`
travava a transação ANTES de chegar no passo problemático (nunca testava esse trecho); com o
lock desbloqueado, pode ter sido só sorte/timing do portal (intermitente). 1 transação não é
suficiente pra confirmar fix — nenhum fix real foi feito ainda no `SearchForGroup.xaml`.

**Confirmação cruzada com Prod (2026-08-18):** job do ticket
(`863ada2e-c5ff-4a2f-a4e9-0b55f6670d6d`, rodou 2026-08-12 16:53–17:12 UTC no `ROBOT1-PRD-AWS`,
falhou 3x consecutivas em `ProcessTransaction`) confirmado como tendo rodado na versão
**5.22.0** do processo (`ReleaseVersionId: 2676274`). Binding do processo no folder `Benefits`
(key `7309F746-E459-478C-A386-1FEBF495B0ED`) tem `AutoUpdate: false` e
`LastModificationTime: 2026-08-10T08:06:37Z` (dois dias antes do job falhar, sem mudança depois)
— ou seja, não teve troca de versão no meio, o job realmente rodou na versão mais recente.
Pacote 5.22.0 publicado 2026-08-10T08:06 UTC por `ahsenturksoy_gsto`, corresponde ao commit
`2c07b5f642f` / PR #3061 (bump `Gusto_Benefits` pra 1.557.0, só dependency bump, sem mudança de
`.xaml` do processo). **Confirma a causa raiz original**: o erro acontece mesmo na library mais
atual — não é lag de publicação, é o passo do `SearchForGroup.xaml` mesmo que nunca foi
corrigido nos 3 fixes anteriores da library.

**Frequência caiu, mas não sumiu (2026-08-18):** 08-17 foi um dia limpo (9/9 itens da fila
`Anthem_MemberUpdates` em Prod processados com sucesso, 0 falhas). Porém 08-18 (hoje) voltou a
falhar: lote de 4 itens no job `b60fb533-2371-41d7-a965-d7e7b161c303` — 1 sucesso, 1 com o
mesmo `UnableToNavigateException` (item 2581513430, ref `500R7000016D7arIAC`, empresa "LFG
LABS", grupo `Q54137`, 08:03-08:05 UTC), e **2 com um erro NOVO e distinto** (ver abaixo). Não
dá pra chamar de "resolvido/estabilizado" — é intermitente, ainda ocorre.

**Erro novo encontrado no mesmo job (2026-08-18), causa raiz DIFERENTE:**
`Could not find the UI element corresponding to this selector: <wnd app='chrome.exe'
cls='#32770' title='Save As' />...` (items 2581513500 e 2581513535, um deles wrapado como
`BusinessException: "Error on carrier portal."` genérico). Rastreado até
`Libraries/Gusto_Benefits/Anthem/Generic/TakeFullPageScreenshot.xaml` (linhas 358-412) — passo
que abre o DevTools do Chrome (`Ctrl+Shift+P` → "capture full size screenshot") e espera o
diálogo nativo "Save As" do Windows pra digitar o nome do arquivo. O diálogo não apareceu.
Hipótese não confirmada: a opção do Chrome "Ask where to save each file before downloading"
pode ter sido desligada na VM do robô — nesse caso o DevTools salva direto na pasta Downloads
sem abrir o "Save As" (comportamento nativo do Chrome quando essa opção está off). Seria infra
da VM, não bug de código — não editar a library sem confirmar isso ao vivo primeiro. Esse
arquivo é compartilhado — afeta também `Anthem_Terminations`. **Decisão do usuário:** manter
BT-74936 focado só no `UnableToNavigateException`; abrir ticket Jira separado pro erro do "Save
As" (ainda não aberto).

**Repro criado na Staging (2026-08-18):** item novo na fila `Anthem_MemberUpdates` (folder
`Benefits`, Staging) — Id `2583744787`, `UniqueKey` `4750eaf0-c2d3-42f0-b21a-eddb8c588209`,
Reference `500R7000016D7arIAC-BT74936-repro`, Status `New`. SpecificContent copiado 1:1 do item
de Prod `2581513430` (mesmo `Id`/`GroupNumber`/`CaseData` — caso da LFG LABS/Q54137) via `uip
orchestrator queue-items add`, seguindo o padrão de [[feedback_uip_cli_json]] (payload extraído
com Python pra evitar erro de escaping manual do JSON aninhado). Usuário vai debugar esse item
no Studio.

**Status update pro Sri (2026-08-18):** draft criado (não enviado) no canal
`#usp-rpa-benops-support-dev` (`C0ANAPHL1NE`) cobrindo BT-74936 (novo erro encontrado, repro em
Staging) e BT-74292 (aguardando Hari validar itens de teste novos). Usuário precisa revisar e
enviar manualmente.

**2 causas novas encontradas e corrigidas (2026-08-19), PR #3156 ABERTA ✅:**
Repro adicional criado na Staging com outro case real de Prod (ref `500R7000013eqx3IAA`, Group
`Q92064`, empresa Scotch Inc., item Prod original `2477607432` falhou 2026-07-20 com
`BusinessException: "Error on carrier portal."`) — copiado pro Staging como item `2585943077`
(ref `500R7000013eqx3IAA-BT74936-repro2`). Debug ao vivo no Studio achou 2 problemas distintos
do `UnableToNavigateException` original:
1. Popup novo "Let us know what you think" (iframe Kampyle) passou a aparecer depois de digitar
   o zip code no `EditEmployee.xaml` — mapeado e dispensado via botão "Not right now".
2. Portal mostra alerta `FWC-ALERT`/`fwcAlertRow` com texto "ZIP CODE NOT FOUN IN DB" — antes
   travava o bot na checagem de estado seguinte; agora lança `BusinessRuleException` limpa.
Fix: `EditEmployee.xaml` (2 `NCheckState` pro popup + 1 `NCheckState` pro alerta de zip) e
`ProcessTransaction.xaml` (fecha o popup antes de tirar screenshot, nos caminhos de sucesso e
catch). `project.json` bumpado 5.22.0→5.22.1. Confirmado ao vivo: bot tratou a transação sem
travar (rethrow limpo + retry automático do Orchestrator).
**Bloqueio de processo corrigido no meio do caminho:** `config.json` ainda tinha o workaround
local (`Z:\Locks`/`Y:\ExceptionScreenshots`, ver bloco acima) — revertido pros paths de rede
(`\\usscl1-fs-3\...`) antes do commit, confirmado sem diff contra develop.
**Git identity bug encontrado e corrigido:** VDI nunca teve `git config user.name`/`user.email`
configurado — primeiro commit saiu com autoria auto-gerada `diogenesribei_gsto@gustocloud.apporto`
em vez do email real. Corrigido com `git config --global` (Diogenes Ribeiro /
diogenes.ribeiro@gusto.com) + `git commit --amend --reset-author`. Vale checar em outras VDIs
novas do time.
**PR #3156:** https://github.com/Gusto/biztech-uipath-rpa/pull/3156 — branch mergeada com
`origin/develop` antes do push (diff limpo, só os 3 arquivos do ticket). Causa raiz original
(`UnableToNavigateException` intermitente no `SearchForGroup.xaml`) continua SEM fix — este PR
resolve só os 2 problemas novos encontrados durante a investigação.
