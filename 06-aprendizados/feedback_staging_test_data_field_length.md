---
name: feedback_staging_test_data_field_length
description: "Não sufixar campos de texto com limite curto (ex: CompanyName) em dado de teste de Staging pra identificação — usar um campo sem limite apertado (ex: UUID) em vez disso"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1966d1d1-b759-4916-95ae-fe62c13a0f05
  modified: 2026-07-23T20:53:01.521Z
---

Ao replicar `SpecificContent`/`SpecificData` real de Produção pra um item de teste em Staging, não adicionar um sufixo identificador (ex: `" (BT-XXXXX STAGING TEST)"`) num campo de texto que tem limite de caracteres apertado no portal de destino (ex: `CompanyName`/nome legal da empresa) — isso pode estourar a validação do próprio portal e mascarar completamente o teste.

**Why:** no BT-74316, sufixei `CompanyName` com `" (BT-74316 STAGING TEST)"`. O nome real já tinha 41 de 45 caracteres permitidos no campo "Legal Name"/"Account Name"/"ERISA Plan Sponsor" do portal BCBS TX — o sufixo estourou o limite, o portal recusou o Continue silenciosamente (sem exceção pro bot, só um alerta na própria página), e o bot seguiu adiante como se tivesse navegado, causando um erro completamente não relacionado (`Select Item` numa tela seguinte que nunca carregou). Perdi tempo investigando o erro errado antes de achar a causa raiz real no HTML salvo.

**How to apply:** pra identificar um item de teste como "não é dado real", usar um campo sem limite de caracteres apertado e que não é validado visualmente/textualmente pelo portal — ex: sufixar o `CarrierOrderSubmissionRequestUUID`/UUID de referência (já era a prática, mantida) em vez do nome da empresa. Se precisar mesmo alterar um campo de texto visível, checar antes o `maxlength`/limite do campo real no HTML do portal.
