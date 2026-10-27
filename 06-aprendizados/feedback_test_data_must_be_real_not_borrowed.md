---
name: feedback_test_data_must_be_real_not_borrowed
description: Ao recriar item de fila de teste, nunca misturar campos reais confirmados (ex. Group_Number__c, Id) com campos copiados de um item de teste diferente/não relacionado — invalida qualquer exceção de negócio observada depois
metadata:
  type: feedback
  originSessionId: 54ae0ab1-a529-41ce-ae99-64267fd4f71b
  modified: 2026-09-16T20:56:50.528Z
---

Durante o teste do BT-75733, recriei itens de fila no Staging usando `Group_Number__c` e `Id` reais (confirmados pela reporter Bri Boyer), mas copiei os demais campos (`ZP_Company_Id__c`, `Application_Id__c`, `Benefit_Order__c`, etc.) de um item de teste antigo e não relacionado, só pra "preencher" o payload sem travar em campo faltando.

Isso quase gerou uma conclusão errada: a busca do grupo funcionou (achou o grupo certo), mas o census baixado do S3 usava o `companyID`/`applicationID` da empresa errada (do item emprestado) — deu "Census policies do not match policies in carrier portal", parecendo um bug real quando era só efeito colateral do dado sintético misturado.

**Correção do usuário:** "não podemos, tem que ser os mesmos dados do item original que ela passou, podemos cometar conclusões incorretas."

**How to apply:**
1. Se só uma parte dos campos reais foi confirmada (ex: pelo reporter/business), NUNCA completar o resto com dados de um item de teste diferente — isso contamina qualquer exceção de negócio observada depois, tornando o resultado do teste não confiável pra reportar de volta ao negócio.
2. Preferir buscar o registro real completo: geralmente o mesmo `Id`/referência que apareceu no relato do problema já está como item `New` na fila real de Production (ainda não processado) — puxar o `SpecificData` de lá (`uip login tenant set Production` + `queue-items get`) e replicar exatamente pra Staging.
3. Se não houver alternativa e for preciso usar template de outro registro, deixar claro pro usuário quais campos são reais e quais são emprestados ANTES de reportar qualquer exceção de negócio como achado — nunca assumir que "deu erro" = "bug confirmado" sem essa checagem.

Relacionado a [[feedback_staging_queue_items]] (mesma lição raiz: nunca confiar em dado de fila reconstruído sem verificar a fonte).
