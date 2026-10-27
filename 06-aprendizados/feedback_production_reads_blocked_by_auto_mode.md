---
name: feedback_production_reads_blocked_by_auto_mode
description: Auto mode classifier bloqueia leituras (queue-items list/get) no tenant Production por padrão — precisa aprovação explícita do usuário mesmo sendo read-only; pedir e trocar de volta pro Staging depois
metadata:
  type: feedback
  originSessionId: 54ae0ab1-a529-41ce-ae99-64267fd4f71b
  modified: 2026-09-16T20:57:17.871Z
---

Ao tentar `uip login tenant set Production` + `queue-items list` (leitura pura, sem escrita) pra pegar o `SpecificData` real de itens confirmados pela reporter, o classificador de auto mode bloqueou com "Permission for this action was denied ... Reason: [Production Reads]" — mesmo sendo GET, não POST/PUT/DELETE.

**How to apply:** ao precisar ler dado real de Production (ex: comparar/replicar item de fila real pra Staging), esperar esse bloqueio e pedir aprovação explícita ao usuário via `AskUserQuestion` em vez de tentar workaround. Depois de terminar a leitura, sempre `uip login tenant set Staging` de volta — nunca deixar a sessão logada em Production por padrão entre uma tarefa e outra.
