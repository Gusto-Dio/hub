---
name: feedback_jira_closing_comment_simple_nontechnical
description: "Jira ticket-closing comments for reporters must be short, plain-language, no technical jargon"
metadata:
  node_type: memory
  type: feedback
  originSessionId: becbd106-6151-4758-b228-ea8dfdaf6fbf
  modified: 2026-10-30T02:45:06.539Z
---

Jira closing comments (for the ticket reporter/business audience, not devs) must be short and non-technical — no exception type names, variable names, PR numbers, or "root cause" framing.

**Why:** User rejected multiple drafts that used terms like "consecutive-failure breaker", "BusinessRuleException", "ProcessVersion 1.6.6" as too technical. The reporter already knows the automation was failing/not working — restating that isn't useful. What they want is: what was actually going wrong (in plain words) + confirmation that after the fix, a real previously-failed transaction was retested and passed.

**How to apply:** For any BenOps/RPA ticket closing comment aimed at the business reporter:
1. Skip preamble like "the bot had X mechanism that wasn't working" — they know it wasn't working, that's why they filed the ticket.
2. Explain in plain words what was actually going wrong (e.g., "it only paid attention to one of the two error types that were happening, so it never noticed failures piling up").
3. State that the fix was validated by re-running a real transaction that had previously failed, and it passed.
4. Close with "Closing this ticket." No technical appendix, no test-plan checklist, no version numbers.

**Atualizacao 30/10 (BT-77264), vale tambem para comentarios de ANDAMENTO, nao so de fechamento:** o comentario espelha na thread do Slack da Tammy via bot, entao e lido pelo negocio. Regras que o Dio impos ao rascunho: (a) nao usar "Staging", "Production", "portal", "enrollment block", "timing problem" nem nomes de activities; dizer "our test", "not live yet", "BSCA website"; (b) NAO expor "the bot" como sujeito que errou ja no primeiro paragrafo; comecar pelas matriculas que paravam e pela causa no site, com "the process was most likely not allowing enough time"; (c) hedge ("most likely") enquanto a causa nao esta provada; (d) nunca dizer "resolved"/"fixed" antes de estar no ar e de uma rodada completa; (e) mostrar o texto exato ao Dio e so postar quando ele disser "posta" (ele pediu para ver antes). Ver [[project_bt77264_bsca_nhe_active_class_not_available]].

This is distinct from [[feedback_language_jira_prs]] (English-only rule, still applies) and from [[feedback_sri_status_update_format]] (Slack async status format, different audience/channel).
