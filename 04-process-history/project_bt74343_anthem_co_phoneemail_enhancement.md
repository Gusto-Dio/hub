---
name: project_bt74343_anthem_co_phoneemail_enhancement
description: "BT-74343 Anthem_CO_GroupSubmission_NewPlan — enhancement aberto 2026-07-16, status New. Portal Anthem exige Phone/Email na tela CompanyInformation (EnrollNow), automação nunca preencheu esses campos. Fix: Phone=companyPhoneNumber, Email=email do benefitsAdmin (confirmado pela Bri Boyer). Falta inspecionar seletor real do iframe ao vivo antes de implementar."
metadata: 
  node_type: memory
  type: project
  originSessionId: f0056cd1-18c8-4221-9a65-cf0f45da71e8
---

BT-74343 (aberto 2026-07-16, status Jira "New") — ticket de enhancement derivado do follow-up do [[project_bt74235_anthem_co_benefitsadmin]] (Problema #2 daquele ticket).

**Não é regressão:** confirmado por leitura do XAML que `ProcessLayer\Enrollment\CompanyInformation.xaml` nunca preencheu Phone/Email — é gap de escopo original que só apareceu agora porque o bot `Anthem_CO_GroupSubmission_NewPlan` não roda em produção há um tempo (ficou mascarado enquanto a fila estava travada com itens antigos).

**Fix a implementar:**
- **Phone** ← `companyPhoneNumber`
- **Email** ← e-mail do `benefitsAdmin`
(mapeamento confirmado pela Bri Boyer no Jira BT-74235, comment 4225630, 2026-07-15)

**Bloqueio conhecido:** os campos reais da tela ficam dentro de um `IFRAME` (`parentid='ServiceCommunityTemplate'`, componente Salesforce Community/Anthem SG Quoting OmniScript) — "Salvar página como .html" não captura o conteúdo do iframe (ver [[feedback_anthem_iframe_html_save_unreliable]]). Precisa inspecionar seletor real ao vivo (`uia-configure-target` com Studio pausado no breakpoint) antes de codar — regra do projeto de não inventar seletor sem ver o elemento real.

**Comunicação:**
- Jira BT-74235 comment 4229013 (2026-07-16): agradecido à Bri, confirmado que não é regressão, avisado que ticket novo seria aberto.
- Slack: usuário avisou a Sri no grupo de dev sobre a abertura do BT-74343 e o motivo (bot não roda há um tempo, gap ficou mascarado).

**Pendente:** implementar o fix (inspeção de seletor ao vivo → editar `CompanyInformation.xaml` no processo, sem tocar Library, seguindo o mesmo padrão de branch/PR do BT-74235).

Related: [[project_bt74235_anthem_co_benefitsadmin]] (ticket original de onde este derivou).
