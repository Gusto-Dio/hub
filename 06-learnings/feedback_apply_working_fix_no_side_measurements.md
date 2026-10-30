---
name: feedback_apply_working_fix_no_side_measurements
description: "Quando o Dio diz que a logica funcionou, aplicar no arquivo real; nao propor medicoes/leituras laterais em Prod que ele ja sabe a resposta"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 09615167-e13b-4ade-9fd7-f65fddc2b3d0
  modified: 2026-10-30T02:44:58.814Z
---

No BT-77264 propus contar duracao de itens em Prod (lentidao das buscas) depois de um teste. Dio respondeu: "pra que quer contar? la em prod ta demorando assim tambem; o erro e o element exists nao achar o ACTIVE e nao a demora, a sua logica funcionou". Ele ja conhece o ambiente lento e queria o fix aplicado.

**Why:** eu inflei o escopo com uma investigacao que ele nao precisava, e leituras em Prod pedem aprovacao a cada vez.

**How to apply:** depois que um teste isolado valida a logica, aplicar no arquivo real (edicoes minimas, validate + build) em vez de abrir novas frentes de medicao. So sugerir leitura extra se ela decidir algo que o Dio nao sabe. Resumir o achado em 2-3 linhas e seguir.

Tambem: quando ele escreve algo curto e ambiguo sobre escopo ("nao vamos corrigir tudo nesse ticket"), CONFIRMAR o sentido antes de agir; eu li como "limitar escopo" e ele queria tratar tudo no mesmo ticket.

Relacionado: [[project_bt77264_bsca_nhe_active_class_not_available]], [[feedback_production_reads_blocked_by_auto_mode]].
