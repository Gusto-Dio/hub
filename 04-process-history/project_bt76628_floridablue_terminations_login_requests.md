---
name: bt-76628-floridablue-terminations-login-requests
description: "BT-76628 FloridaBlue login — 14/10: MFA code (SMS 3395 -> Google Voice -> Gmail) para de chegar; aguardando Ebenezer/Bri (Automation Ops); fix de espera portado p/ Terminations só local"
metadata:
  node_type: memory
  type: project
  modified: 2026-10-14
---

Ticket BT-76628 (12/10, prioridade Low, 18 itens): jobs FloridaBlue_NewHireEnrollment/_Terminations/_MemberUpdates faultando no login. Jira In Progress, assignee Dio.

**Causa real encontrada (14/10):** o MFA do Florida Blue vai por SMS para o número final 3395 e chega no Gmail da `Credential_Gmail` via Google Voice (assunto "New text message from 352583", pasta "Access Token (Florida Blue)"). Último código chegou 14/10 ~10h; depois nada (Inbox/spam/label), mesmo com 30+ min entre logins e credenciais conferidas no 1Password. `GetAccessCode` (lib Gusto_Benefits/FloridaBlue/Generic) lê IMAP só não-lidas, Date >= start-30s, loop de 120s, e sai SEM erro se não achar — por isso log "success" e depois "invalid credentials" aos 180s.

**Estado do código:** branch local `BT-76628-floridablue-terminations-login-throttle` (sem commit): InitAllApplications do NHE (#3398) copiado p/ Terminations + `MinMinutesBetweenLogins=11` + projectVersion 6.1.3. Testado no Studio 3x: não exercitou o fix (1º login nunca é retentado). Falta: MemberUpdates, tentativa extra no 1º login, Click 'Requests' (screenshots Prod).

**Contato:** Oscar disse que Automation Ops checa isso (Tammy Borders, que está off); no lugar, "Ebenezer or Bri" (não Jenna). Comentário já postado no Jira (14/10). Aguardando Ebenezer responder. Contexto: ago/2026 o Hari tinha tarefa ON HOLD (atraso da IT, escalada pelo Jonathan Boice) para trocar o e-mail do MFA por um genérico carrierops.

**Why:** sem o SMS chegando, nenhum fix de código resolve o login.
**How to apply:** ao retomar, ver resposta do Ebenezer; se o Voice voltar a encaminhar, rodar de novo e só então decidir PR do fix de espera. Não ficar re-logando à toa (conta compartilhada com bots de Prod).
