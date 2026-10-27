---
name: reference-login-circuit-breaker-locks-share
description: "Arquivos .breaker.json no share de locks (MFA_UHC etc.) explicam \"Login failed due to invalid credentials\" quando a credencial na verdade está ok"
metadata: 
  node_type: memory
  type: reference
  originSessionId: fd26cff3-c431-41f8-b169-74ecb059d3d2
  modified: 2026-09-09T17:55:41.280Z
---

Share: `\\fs3-prd-aws.gustocorp.com\BizTech\RPA\Locks` (migrado do `usscl1-fs-3` em ago/2026; path do asset `Asset_LocksFolderPath`).

Contém, por `LockKey` (ex: `MFA_UHC`):
- `<LockKey>.json` — lock ativo no momento (token, holder, acquiredUtc, ttlSeconds). Ausência = lock livre.
- `<LockKey>.breaker.json` — circuit breaker: `state` (`Closed`/`Open`), `consecutiveFailures`, `openCount`, `openUntilUtc`, `lastReason` (texto real do último erro), `lastHolder`, `lastFailureUtc`, `lastSuccessUtc`.
- `Credential_<Nome>.breaker.json` — mesma ideia, mas por asset de credencial (`state: Closed` + `lastSuccessUtc` recente = a senha em si está OK).

**Por que isso importa:** o `LockKey` (ex: `MFA_UHC`) é compartilhado entre **todos os robôs/tenants** que usam aquele processo de login — não é por tenant. Se um robô de Produção falhar 3x seguidas (ex: por um seletor de UI quebrado, nada a ver com senha), o breaker do `MFA_UHC` abre (`Open`) até `openUntilUtc`, e **qualquer outra tentativa de login** (inclusive um debug seu no Staging) cai no mesmo fallback genérico `"Login failed due to invalid credentials."` enquanto o breaker estiver aberto — mesmo que a senha esteja perfeita.

**How to apply:** antes de assumir que é senha errada, ler os dois arquivos:
1. `Credential_<Nome>.breaker.json` — se `state: Closed` e `lastSuccessUtc` recente, a senha está boa.
2. `<LockKey>.breaker.json` — se `state: Open`, olhar `lastReason` (geralmente é a mensagem de erro real, ex: "Could not find the UI element...") e `openUntilUtc` pra saber quando volta a permitir tentativa. `lastHolder` mostra qual máquina/robô causou a última falha (ajuda a saber se foi Prod contaminando o teste em Staging).

Visto em [[project_bt75501_uhc_samx_memberupdates_name_already_updated]] (2026-09-09): breaker do `MFA_UHC` estava `Open` por falha de seletor de UI em `ROBOT1-PRD-AWS` (Produção), bloqueando um debug de Staging que reportava "invalid credentials" — a credencial em si (`Credential_UHC_SAMx_MOps`) estava com `state: Closed` e sucesso recente, então não era ela. (Nesse caso específico, depois se confirmou que a senha do Staging TAMBÉM estava desatualizada de verdade — os dois problemas coexistiam; então sempre checar os dois arquivos, não parar no primeiro que parecer a causa.)
