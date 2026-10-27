---
name: bt76973-bcbs-ma-popup-blocked-chrome-closed
description: "BT-76973 (BCBS_MA NHE/MemberUpdates \"No open windows found for chrome.exe\") — causa = Chrome dos robôs bloqueando pop-up; Dio ajustou a permissão, backlog reprocessado e 3 filas zeradas (22/10 01:50 UTC, sem duplicata do builder), Jira comentado; falta rodada 06:00 e política/lib permanentes"
metadata:
  node_type: memory
  type: project
  originSessionId: 830837ca-d071-494d-82af-c67ea5973aff
  modified: 2026-10-22T01:48:43.445Z
---

Ticket BT-76973 (Medium no Jira, atribuído ao Harinath Reddy Mora, status Scheduled; reporter Tammy Borders). Processos `BCBS_MA_NewHireEnrollment` e `BCBS_MA_MemberUpdates` (filas de mesmo nome, folder Benefits Prod OU 46023); a `BCBS_MA_Terminations` usa a mesma lib e teve 1 item afetado.

**Sintoma:** jobs das 06:00 faultavam todo dia de 15/10 a 21/10 com `No open windows found for 'chrome.exe'` (primeiro no `Attach Browser 'chrome.exe Home'` de `SearchForGroup.xaml`), em robôs variados (ROBOT1/4/5/6-PRD-AWS). Rodavam bem até 14/10; nenhum commit nos processos desde 15/09.

**Causa (confirmada pelo Dio assistindo o job):** o Chrome dos robôs passou a bloquear pop-up. `Libraries\Gusto_Benefits\BCBS_MA\NavigateToHome.xaml` clica em `BluesEnroll` (abre o portal numa janela nova), checa `BluesEnrollexists` mas NÃO usa o resultado, e depois faz `Close Tab` na aba `Home` incondicionalmente. Com o pop-up bloqueado a aba `Home` é a única, então o Chrome inteiro fecha e o robô segue o código até falhar na busca. O Init do processo (`OpenNonPrivatePortal` → `LoginToBCBS_MA` → `NavigateToHome`, tudo da lib Gusto_Benefits) não lança exceção, por isso o log do Init parece "ok".

**Como virou (21/10 à noite):** Dio pegou o controle de uma máquina e marcou "sempre permitir pop-ups"; o job passou a processar. NHE: 24 de 31 transações ok, só 1 erro de Chrome (antes do ajuste). Comentário público postado no Jira (id 5084564), em inglês, simples, sem formatação, sem citar infra e sem pendências. Dio fechou BT-76855 na mesma sessão ([[project_bt76855_advising_uhc_packetcollection_object_reference]]).

**Impacto nas filas:** itens NÃO ficaram Failed; os 3 itens pegos por job faultado (06:01/06:03/06:05) ficam InProgress e viram Abandoned ~24h depois (~06:06 do dia seguinte). Recoloquei 14 itens (7 NHE + 7 MemberUpdates) com payload idêntico (SpecificData bruto); 12 processaram ok ou com erro de negócio; apaguei 9 órfãos InProgress (Dio rodou o script). Terminations: 1 item de Chrome reprocessado por Dio pela UI.

**Resultado final (22/10 ~01:50 UTC):** builder `MemberSubmissions_QueueBuilder` (roda ~01:00 UTC, ROBOT4/6, cria os itens das 3 filas) NÃO duplicou nenhum Reference; só recria o que segue pendente no Salesforce (o que processou ok não volta). Dio rodou os 3 processos à mão às 01:14 UTC: MemberUpdates 4/4 ok, Terminations 8/8 ok, NHE 8 ok + 2 erros de negócio (`BifGkIAJ` Group not in carrier portal, `BiirKIAR` Policy Name mismatch); filas zeradas, zero erro de Chrome. NHE e Terminations rodaram juntos na ROBOT4 sem se atrapalhar.

**Pendências:** (1) olhar a execução das 06:00 UTC de 22/10 (NHE/MemberUpdates sem erro de Chrome); (2) (feito: sem duplicata do builder); (3) o ajuste foi manual numa máquina, falta política Chrome `PopupsAllowedForUrls` (domínio do portal, `secure-enroll.com`) para todos os robôs; (4) conserto de resiliência na lib `NavigateToHome` (só fechar a aba `Home` se o pop-up abriu; senão lançar erro "popup blocked") exige bump + PR + rebind dos processos que usam a lib; (5) Terminations tem falhas de negócio recorrentes não relacionadas (data de término com data do dia em 3 Reference). Planilha de tracking: BT-76973 não está lá (nada a atualizar).

Relacionado: [[reference_uip_queue_items_cli_gotchas]], [[feedback_production_reads_blocked_by_auto_mode]].
