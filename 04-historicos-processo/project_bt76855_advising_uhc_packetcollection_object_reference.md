---
name: bt76855-advising-uhc-packetcollection-object-reference
description: "BT-76855 (Low, Bug) — Advising_UHC_PacketCollection: fix LIVE em Prod (v1.17.16, PR #3452 mergeada 21/10, rebind feito, comentário no Jira postado); ticket ainda In Progress, falta monitorar jobs e fechar"
metadata:
  node_type: memory
  type: project
  originSessionId: a208c49e-d4c1-423d-b931-65427dd6e10a
  modified: 2026-10-21T23:08:21.505Z
---

Ticket BT-76855, Low, Bug, assignee Dio, **FECHADO por Dio em 21/10** (após o comentário; monitoramento dos jobs em Prod fica opcional). Processo = `Processes/Benefits/CarrierAutomations/Advising/Packet_Collection/UnitedHealthcare_SAM` (name `Advising_UHC_PacketCollection`; o `UnitedHealthcare_SAMx` é OUTRO processo). Contexto: [[project_bt75456_uhc_packetcollection_legacy_windows_migration]], [[project_packet_collection_priority_window_2026_09]].

**Sintoma (Jira):** upload do pacote dá "Object reference not set…", o PDF fica na Temp e sobe junto com o pacote da próxima transação bem-sucedida → pacote de um cliente na oportunidade de outro.

**Estado (21/10 noite): FIX LIVE EM PRODUÇÃO.**
- PR #3452 aprovada por oscarmiza (LGTM) e **mergeada por Dio em 21/10 22:46 UTC**. Build da PR #14965 e build develop pós-merge #14967 passaram.
- Autodeploy publicou `Advising_UHC_PacketCollection:1.17.16` no feed de Prod às 22:47 UTC.
- **Rebind manual feito com aprovação explícita do Dio:** Process (key `30A49D63-00BC-43A8-B59C-B3E581D49036`, folder Benefits, Prod) estava em 1.17.15 → agora 1.17.16, `IsLatestVersion: true`, verificado. Tenant do uip voltou para Staging.
- **Comentário de fechamento postado no Jira** (comment 5084241, inglês, simples, sem formatação; é público, o reporter John Falk vê). Status do ticket NÃO foi transitado.

Mudança: só o processo. `ProcessTransaction.xaml` (`tempFolder` = `Temp\UHC_SAM\`, delete+create antes do CollectPacket, log "Bot temp folder reset"), `SavePacket.xaml` (Throw se `Not File.Exists` após o While de 60 s), `project.json`. Pin `Gusto_Generic_SalesForce` 2.0.1 inalterado. **Sem teste E2E** (fila Staging sem itens; Dio decidiu abrir assim). **Mudança na lib DESCARTADA pelo Dio** (lib 2.0.2 no Staging fica sem uso). PR sem assinatura Claude, corpo em inglês ([[feedback_pr_no_claude_signature_no_tx_table]]).

**Causa do leak (confirmada no código):** `TempFolder` compartilhado entre os 10 processos de Packet Collection; `UploadFile` só apaga os arquivos se TUDO deu certo; `CleanupAndPrep` só roda 1x por job. Falha deixa arquivo na pasta → próxima transação sobe junto.

**Causa do NRE (evidência de Production, 21/10):** 44 itens Failed com o NRE em 14 jobs (06, 07, 14, 20/10), fila 9423 `UHC_Packets`, folder Benefits (OU 46023). O NRE vem do `Throw SFAttachmentException` do estado final do `UploadFile` com `SystemError` capturado DENTRO de uma activity Salesforce — não da condição de transição de `attachmentStatus`. Padrão: transação N falha no `CollectPacket` ("Save As dialog did not appear" / "packet could not be collected"); N+1 baixa o PDF, `SavePacket` ok, `UploadFile` dá NRE. Hipótese (2 jobs comparados, não prova): lixo na pasta compartilhada quebra todo upload seguinte. O fix de pasta própria quebra a cadeia independentemente.

**Dados de teste:** todo item (Staging e Prod) tem `sfdc_link` em SFDC de produção e planilha Google real → clonar escreve em sistema real. Ver [[feedback_test_data_must_be_real_not_borrowed]], [[feedback_staging_queue_items]], [[feedback_uip_queue_items_get_repascalizes_keys]]. CLI: `uip or queue-items list` limit máx 100; `get` precisa `--folder-path Benefits`; trocar tenant com `uip login tenant set X` e SEMPRE voltar para Staging ([[feedback_production_reads_blocked_by_auto_mode]]). `uip or processes list` não tem `--search`; filtrar com `--output-filter` JMESPath.

**Próximos passos:** (1) monitorar próximos jobs de Packet Collection UHC_SAM em Prod: log "Bot temp folder reset", sem NRE em cascata (o fix nunca rodou com dado real); (2) se limpo, transitar/fechar o ticket; (3) pendências conhecidas, fora do escopo: duplicação de upload no retry se `UpdateBotSuccess` falhar; causa do "Save As dialog did not appear" (política Chrome AutomaticDownloadsAllowedForUrls); os outros 9 processos de Packet Collection ainda usam a pasta compartilhada.
