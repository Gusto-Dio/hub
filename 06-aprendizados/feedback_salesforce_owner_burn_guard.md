---
name: feedback_salesforce_owner_burn_guard
description: Por que uma transação "queima" o Owner no Salesforce (bloqueio permanente de reteste) mesmo sendo um bug técnico, não de negócio
metadata:
  node_type: memory
  type: feedback
  originSessionId: 42c9a88d-1b65-4c7f-bcc0-9a1eebd00374
---

Em processos de GroupSubmission BCBS_TX (e provavelmente outros carriers com o mesmo padrão de `ProcessTransaction.xaml`), existe um guard de segurança que reatribui o campo `OwnerId` do `Carrier_Order__c` no Salesforce real (não sandbox) pra uma fila de revisão manual sempre que a automação falha — mas **só em certas condições**, não em toda falha.

**Código exato** (`ProcessTransaction.xaml`, dentro do Catch geral do `wbProcess`):
```
If exception.GetType.Name="BusinessRuleException"
   AndAlso NOT(message.Contains("Order is no longer in Automation Queue"))
   AndAlso NOT(message.Contains("Order is no longer in Ready for Submission Prep stage"))
Then → Invoke UpdateCarrierOrder (in_AutomationStatus="Failed", in_OwnerId=<fila de revisão manual>)
```

**Why:** exceções técnicas genéricas (`ApplicationException`, ex: `InvalidUiElementException` de um bug de UI Automation) NUNCA disparam essa reatribuição — só uma `BusinessRuleException` que não seja um dos dois guards de "já não está mais na Automation Queue" dispara. Na prática, isso quase sempre significa: **o guard "Portal application already started on a previous attempt" é o verdadeiro gatilho** — ele dispara na 2ª tentativa automática do Orchestrator (quando `Progress="PortalApplicationStarted"` foi setado na 1ª tentativa e a 1ª falhou depois disso), e como essa mensagem específica NÃO está na lista de exclusão, ele PRÓPRIO aciona a reatribuição de Owner.

**Consequência prática:** com `MaxNumberOfRetries=1` + `AcceptAutomaticallyRetry=true` (configuração comum dessas queues), **qualquer transação que falhe depois de já ter avançado no portal (Progress marcado) acaba com o Owner "queimado" em poucos minutos**, automaticamente, mesmo que a causa raiz seja um bug técnico simples (ex: race condition de UI) que nada tem a ver com o negócio. Confirmado empiricamente: de 10 itens `Failed` recentes verificados na fila `BCBS_TX_GroupSubmissions_NewPlan` de Produção, **todos** já estavam queimados.

**Como aplicar:**
1. Antes de reusar uma transação de Produção pra reproduzir um bug em Staging, checar `uip or queue-items get-last-retry <key> --output-filter "{ExType: ProcessingExceptionType, ExReason: ProcessingExceptionReason}"` — se `ExReason` já for uma dessas duas mensagens de guard, o registro Salesforce já está queimado e recriar o queue item NÃO vai ajudar (o bloqueio é no Salesforce, não no Orchestrator).
2. O único tipo de transação seguro de reusar/re-testar é uma genuinamente `Status=New` (nunca processada) — mas cuidado: se ela falhar UMA VEZ na sua sessão de teste (mesmo em Staging, já que Staging bate no mesmo Salesforce real) e depois for retried automaticamente e cair no guard "Portal application already started", ela também fica queimada — mesmo sem nenhuma ação manual sua, o próprio Orchestrator já faz isso.
3. Deixar um item de teste "órfão" (ex: sessão de debug fechada no meio) com `Progress="PortalApplicationStarted"" ativa esse mesmo mecanismo assim que o Orchestrator tentar reprocessá-lo — **é fácil queimar um registro sem querer só por deixar Studio aberto/fechado no meio de um teste.**
4. Não existe reset via CLI/Orchestrator — só resetando o campo `OwnerId` direto no Salesforce (acesso de escrita que provavelmente não temos, ver [[feedback_assets_update_403]] pro padrão de permissões limitadas nesta conta).

Related: [[project_bt74147_bcbs_tx_add_dependent]], [[feedback_staging_queue_items]].
