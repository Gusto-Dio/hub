---
name: feedback_check_dependencylock_before_pr
description: "Checar dependencylock.json do develop vs project.json ANTES de abrir PR, não só depois do Buildkite falhar"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a75c34b6-0c48-41ed-82ae-039d50a60c8c
  modified: 2026-07-23T20:52:34.261Z
---

Buildkite's `check_dependency.sh` faz match exato de string entre a versão pinada no `project.json` do processo e a versão em `dependencylock.json` na raiz do repo (que reflete `develop`). Se outro PR não relacionado bump a lib globalmente enquanto meu processo não é tocado há um tempo, meu `project.json` fica defasado mesmo sem eu ter feito nada errado — e só descubro depois que o Buildkite já rodou e falhou.

**Why:** aconteceu na BT-73904 (Gusto_Benefits 1.551.1 vs 1.552.8 esperado) — só vi o erro depois de já ter aberto a PR, porque não conferi o lock antes.

**How to apply:** Antes de abrir PR (ou até antes de começar a editar), correr `git show origin/develop:dependencylock.json | grep "<NomeDaLib>"` e comparar com o `project.json` do processo. Se divergir, bump o `project.json` já junto com o fix, evita um ciclo extra de "abrir PR → Buildkite falha → corrigir → push de novo".

**2º modo de falha, mesma causa raiz (BT-74147, 2026-07-10):** quando a dependência no `project.json` não é um pin exato (ex: `"1.551.1"` em vez de `"[1.551.1]"`), abrir o Studio ou rodar `uip rpa build`/`pack` pode disparar um restore que sobe silenciosamente a versão pra última disponível na feed (ex: `1.551.1` → `1.553.0`) — mesmo sem eu tocar na dependência. Isso também diverge do `dependencylock.json` do develop. Sempre re-checar o `dependencylock.json` depois de QUALQUER `build`/`pack`/restore nesta sessão, não só uma vez no início — o valor pode ter mudado sem eu perceber.

**3ª ocorrência (BT-74316, 2026-07-23) — eu mesmo não segui o próprio conselho:** abri a PR #2961 sem checar o `dependencylock.json` raiz antes, Buildkite falhou (`Please upgrade Gusto_Benefits to version 1.553.1`), só corrigi depois do usuário colar o erro. **Lição reforçada: rodar essa checagem faz parte do checklist pré-PR de qualquer ticket, sempre, antes do primeiro `git push` — não é opcional nem "só se der tempo".** Comando rápido: `git show origin/develop:dependencylock.json | grep -i "<NomeDaLib>"` comparado ao `project.json` do processo, executado ANTES de commitar/push, não depois do Buildkite reclamar.
