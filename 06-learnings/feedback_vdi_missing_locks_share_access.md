---
name: feedback_vdi_missing_locks_share_access
description: RESOLVIDO ✅ (2026-08-17) — VDI sem acesso a servidores gustocorp (ex \\usscl1-fs-3) era bloqueio de grupo Cloudflare; hostname curto (não-FQDN) ainda falha (achado 2026-08-21) — workaround config.json local + drive mapeado
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e6b44297-0708-433e-a875-660712c4ce8e
  modified: 2026-08-21T17:26:08.940Z
---

Debug local no Studio de qualquer processo Anthem que passa pelo login do broker portal
(`AcquireLoginLock`/`ReleaseLoginLock`, `Libraries/Gusto_Generic_Activities`) falha com
`Acquire Anthem login lock (serialize MFA): Exception has been thrown by the target of an
invocation.` se a VDI não tiver acesso ao share `\\usscl1-fs-3\BizTech\RPA\Locks`
(`Test-Path` retorna `False`). Confirmado com Oscar (2026-08-14, DM): esse lock é um
"traffic light" pra serializar login/MFA entre bots que compartilham a mesma conta —
"If you have access to the folder, then it should work fine."

**Why:** apesar do `AcquireLoginLock.xaml` ser desenhado como fail-open (não deveria travar
a execução se não conseguir acessar o lock), na prática a falta de acesso ao share derruba
a activity com exceção mesmo assim — vale investigar o motivo depois, mas por ora o caminho
mais rápido é pedir acesso.

**How to apply:** se esse erro aparecer em debug local (não em Produção — o robô roda em
máquina diferente com acesso ao share), não tratar como bug de código. Pedir acesso ao
path `\\usscl1-fs-3\BizTech\RPA\Locks` via canal de suporte Apporto/IT antes de continuar
o debug. Ver [[project_bt74936_anthem_memberupdates_navigate_er]] — foi nessa investigação
que isso apareceu, bloqueando o debug ao vivo do erro real (`UnableToNavigateException` no
Employer Access, um passo depois do login).

**Pedido de acesso enviado (2026-08-14, 13:02 -03):** mensagem no Slack pro Eric Chandler
(canal `C0B148KNG0J` = `#apporto_deployment_uipath`, thread `1786723356.760949`), cc Sri e
Oscar, pedindo acesso a `\\usscl1-fs-3\BizTech\RPA` na VDI Apporto.

**Diagnóstico aprofundado na mesma thread (2026-08-14):** não é erro de permissão — é
provavelmente domain trust entre `gustocloud` (domínio da sessão VDI) e `gustocorp` (domínio
do file server). Confirmado: porta/DNS OK, mas Windows não resolve/abre o path (erros 53/64,
não "access denied"). Duas tentativas de conexão, **ambas falharam com o mesmo erro**:
1. Sessão padrão da VDI (`gustocloud\diogenesribei_gsto`, aberta automaticamente via Okta/Apporto SSO).
2. Credencial manual `gustocorp\diogenes.ribeiro` adicionada no Windows Credential Manager
   pro FQDN `usscl1-fs-3.gustocorp.com` (senha conhecida/correta da conta, confirmada com o Eric).

**Confirmado 2026-08-17:** `Test-Path \\usscl1-fs-3\BizTech\RPA\Locks` continua `False` na VDI.
Thread tinha ficado parada desde 2026-08-14 17:36 (última resposta minha cortada/incompleta:
"I don't [have a separate password for gustocloud\diogenesribei_gsto]" — Eric tinha perguntado
se dava pra remapear o drive com `gustocorp\diogenes.ribeiro`, já tentado no item 2 acima).
**Draft de follow-up criado no Slack** (não enviado ainda, `draft_id: Dr0BRMNGBZPS`) explicando
as duas tentativas falhas + que não existe senha separada pra `gustocloud\diogenesribei_gsto`
(login é 100% automático via SSO) — pedindo alternativa (ex: IT provisionar o trust/mapping
no nível da imagem da VDI).

**Status:** bloqueio de infra CONTINUA aberto. Debug ao vivo do BT-74936 seguirá pausado até
o Eric/IT resolver o domain trust ou indicar outro caminho.

**Workaround encontrado (2026-08-17):** mapear drive manualmente via `net use` contorna o
domain trust, mesmo com o UNC continuando `False` no `Test-Path`:
```
net use Z: "\\usscl1-fs-3.gustocorp.com\BizTech\RPA" /persistent:no
net use Y: "\\usscl1-fs-3.gustocorp.com\BizTech" /persistent:no
```
Ambos resolveram (`Test-Path Z:\Locks` → `True`, `Test-Path Y:\ExceptionScreenshots` → `True`)
mesmo com `Test-Path \\usscl1-fs-3\BizTech\RPA\Locks` continuando `False` na mesma sessão —
ou seja, não é bloqueio total do domain trust, é algo específico de resolução de path UNC
direto (SMB/DFS?) que `net use` contorna.

**Como aplicar em debug local:** os processos Anthem guardam esses paths em
`Data/config.json` (`LocksFolderPath`, `ExScreenshotsFolderPath`) — **não** hardcoded na
library. Pra debugar localmente:
1. Mapear os drives acima.
2. Editar temporariamente o `config.json` do processo pra apontar `Z:\Locks` e
   `Y:\ExceptionScreenshots` em vez do UNC.
3. **Reverter antes de qualquer commit/PR** — o robô em Produção roda em máquina com acesso
   direto ao UNC e não tem os drives `Z:`/`Y:` mapeados.

**CAUSA RAIZ REAL E FIX DEFINITIVO (2026-08-17, thread completa com Eric Chandler,
`#apporto_deployment_uipath`, thread_ts `1786723356.760949`):** não era domain trust nem
credencial — era um **grupo de acesso do Cloudflare** que o Eric precisou adicionar minha
conta. Depois de: (1) Eric me adicionar no grupo certo do Cloudflare, (2) eu reautenticar
com o Cloudflare, e (3) **reiniciar a VDI** (reautenticar sozinho NÃO foi suficiente),
`\\usscl1-fs-3.gustocorp.com\...` passou a funcionar direto, sem precisar mais do workaround
`net use` Z:/Y:. Confirmado funcionando em 2026-08-17 18:15.

**Runbook completo documentado no Notion (2026-08-19):** [VDI Network Drive Access — gustocorp.com File Server](https://app.notion.com/p/3c1ad673c6c281519ec0c4cf32334ab7)
(BenOps RPA Hub → Runbooks) — os 3 passos (pedir grupo Cloudflare, configurar Windows
Credential Manager com FQDN completo + `gustocorp\usuário`, reautenticar + reiniciar VDI)
pra qualquer um do time que bater nesse mesmo bloqueio.

**Novo achado (2026-08-21, durante debug do BT-75006 Oxford_GroupSubmissions_NewPlan —
mesma família UHC SAMx, não Anthem):** o fix de Cloudflare resolveu o acesso via FQDN, mas
**hostname curto continua falhando** — são causas raiz diferentes:
```
Test-Path "\\usscl1-fs-3.gustocorp.com\BizTech\RPA\Locks"  → True
Test-Path "\\usscl1-fs-3\BizTech\RPA\Locks"                 → False
```
O `Data/config.json` de vários processos (Oxford incluso) guarda `LocksFolderPath` com o
hostname **curto** (`\\usscl1-fs-3\...`), então mesmo com o acesso já liberado, o path
configurado não resolve nessa VDI — não é falta de acesso, é resolução de nome curto (DNS
suffix search list). `Z:` já estava mapeado (`net use` mostrou `Z: → \\usscl1-fs-3.gustocorp.com\BizTech\RPA`,
persistente), então o workaround de editar o `config.json` pra `Z:\Locks` continua válido e
mais simples que trocar pra FQDN. Mesma regra: editar local só pra debugar, **reverter antes
de commit/push/PR** — Produção acessa via UNC direto, sem os drives mapeados.
