---
name: bt76865-floridablue-login-invalid-credentials-followup
description: "BT-76865 FloridaBlue (NHE/Terminations/MemberUpdates) — 20/10: causa raiz = GetAccessCode digitava o SMS inteiro; lib 1.559.39 (#3437) + 3 PRs de processo (#3438-3440) mergeadas, builds verdes, Jira comentado; falta conferir jobs 04:00 UTC em Prod e avisar Tammy"
metadata:
  node_type: memory
  type: project
  originSessionId: 5974d365-6e5f-47be-9c99-6d89516de84d
  modified: 2026-10-20T16:35:15.412Z
---

BT-76865 (Tammy Borders, 2026-10-19, Low, In Progress, assignee Dio): `FloridaBlue_NewHireEnrollment`, `_Terminations`, `_MemberUpdates` faultando no login com "Login failed due to invalid credentials." (77 itens na fila). Continuação de [[project_bt76628_floridablue_terminations_login_requests]] (encaminhamento SMS→Google Voice→Gmail do MFA, escalado p/ IT, não era nosso).

**Causa raiz (20/10):** o encaminhamento voltou, mas `Libraries/Gusto_Benefits/FloridaBlue/Generic/GetAccessCode.xaml` extraía o código com `Split("Your verification code is:")(1).Split("."c)(0)`. SMS real: "Your verification code is:125829 and it's valid for 15 minutes. Enter the code..." (sem ponto após o código) → bot digitava "125829 and it&#39;s valid for 15 minutes" → portal: "We don't recognize that code. Error Code: 12000" → `LoginToFloridaBlue` (catch-all) lança "invalid credentials". Senha/asset NÃO eram o problema.

**Fix e entrega (tudo mergeado 20/10, Hari aprovou):**
- Lib `Gusto_Benefits` 1.559.38→1.559.39, PR #3437: regex `verification\s+code\s+is[^0-9]{0,30}(\d{4,8})`, LogMessage Warn se não achar código, `ui:GetValue` (ContinueOnError) loga texto do alerta do portal no LoginToFloridaBlue. NÃO mudar a mensagem "Login failed due to invalid credentials." (Main.xaml faz `.Equals` e zera MaxInitRetryNumber p/ não retentar login na conta compartilhada).
- Processos (só `Gusto_Benefits`→1.559.39 + projectVersion): Terminations #3438 (6.1.3), NHE #3439 (6.0.5), MemberUpdates #3440 (6.0.4). Builds Buildkite #14919/#14921/#14923 passaram; Dio disse que o rebind em Prod foi feito (eu não conferi versões ativas em Prod).
- Staging: pacotes publicados; rebind feito (Terminations 6.1.3, MemberUpdates 6.0.4). NHE NÃO tem Process no Staging (só pacote).
- Jira: comentário final postado (id 5072538, inglês, sem citar processo testado). Ticket ainda In Progress.
- `FloridaBlue_MemberUpdates_WithoutQueue` (Legacy, lib 1.399.3, mesmo `name` do MemberUpdates) = cópia morta, não tocar.
- Throttle do BT-76628 (MinMinutesBetweenLogins=11) ficou FORA; continua só na branch local `BT-76628-floridablue-terminations-login-throttle` (não commitada). Studio run de teste foi no STAGING (folder 48382), então o "EE does not exist" não queimou nada em Prod.

**Atualização 20/10 fim do dia:** Dio mandou o status ao grupo (Sri/Oscar) dando BT-76865 como Done, junto de BBO-3914 e BT-76745 (Done); Jira BT-76865 ainda aparece In Progress (não movi sem confirmação). Mensagem de status no padrão: bullet por ticket com só o número (sem URL) + nome + status, em inglês.

**Pendente:** (1) conferir jobs Prod 04:00/04:10/04:20 UTC (Term/NHE/MemberUpd) — NHE falhava crônico desde 20/09, pode ter outra causa pós-login; (2) avisar a Tammy; (3) fechar o ticket só após jobs ok; (4) limpar worktrees `U:\Projects\wt-bt76865*` (lib, -term, -nhe, -mu) e branches se quiser.

**Why:** "invalid credentials" é catch-all; sem o texto real do alerta não dava p/ separar causas. **How to apply:** se voltar a falhar, ler no log o novo "portal alert on login page: ..." / "no access code found in folder" antes de suspeitar de senha.
