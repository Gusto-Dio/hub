---
name: project_bt74235_anthem_co_benefitsadmin
description: "BT-74235 Anthem_CO_GroupSubmission_NewPlan (ticket Jira status Done) — bug original BenefitsAdmin CONCLUÍDO (PR #2932 merged+produção); follow-up 2026-07-15: fix de NullReferenceException no census (validado, queue limpa 16→0 New); 2 problemas novos sem ticket próprio ainda: race condition no Broker TIN (Quoting, não implementado) e Phone/Email faltando no CompanyInformation.xaml (Enrollment) — mapeamento de campos confirmado pela Bri (Phone=companyPhoneNumber, Email=benefitsAdmin), falta só inspecionar seletor real no iframe ao vivo"
metadata: 
  node_type: memory
  type: project
  originSessionId: 54402a72-0c48-4a2e-91be-db3a5cf00620
---

BT-74235 (Task, Medium priority, reportado por Bri Boyer 2026-07-13, atribuído a Diogenes) — `Anthem_CO_GroupSubmission_NewPlan` faultando consistentemente com `KeyNotFoundException: 'BenefitsAdmin' was not present in the dictionary`. 1 ordem na fila de Produção, ~3 dias de prazo.

**Root cause confirmado por live debug (não só por análise estática):** `Libraries/Gusto_Benefits/Anthem/NewPlan/ProcessQueueItem.xaml:398` faz `in_TransactionItem.SpecificContent("BenefitsAdmin")` (PascalCase, case-sensitive) — herdado do fix da [[project_bt73710_anthem_ca_newplan]] (BT-73710, 2026-06-24: camelCase→PascalCase). Mas o dado REAL da fila (`SpecificData.DynamicProperties`, confirmado via OData `$select=SpecificContent` bruto E via debug live no Studio com Watch em `in_TransactionItem.SpecificContent`) é genuinamente **camelCase** (`benefitsAdmin`) — tanto para CO quanto para CA (bytes idênticos verificados). O CLI `uip or queue-items get --all-fields` mostra `SpecificContent` com a primeira letra maiúscula — isso é só normalização cosmética do client, NÃO reflete a chave real armazenada nem a que o robô recebe em runtime. Confirmado 100% com breakpoint real no Studio Desktop conectado ao Staging: o erro reproduziu exatamente igual usando os mesmos dados reais.

**Por que CA "funciona" com o mesmo código PascalCase permanece um mistério não resolvido** — mesma versão de lib (1.552.8), mesmo project.json, mesmo RobotId, dado raw idêntico (camelCase) nos dois. Não vale a pena investigar mais — o fix abaixo resolve independente da causa exata do comportamento do CA.

**Fix implementado (branch `BT-74235-Anthem-CO-GroupSubmission-NewPlan-benefitsadmin-fix`), 100% no arquivo do PROCESSO — NÃO tocou a Library** (decisão explícita do usuário: "não corremos o risco de mexer na lib e impactar outros processos"):

Em `Processes/Benefits/CarrierAutomations/GroupSubmission/Anthem/Anthem_CO_GroupSubmission_NewPlan/ProcessLayer/ProcessTransaction.xaml`, um novo `Assign` logo após `ProcessConfigFile` e antes de `gan:ProcessQueueItem`:
```vb
in_TransactionItem.SpecificContent = in_TransactionItem.SpecificContent.Where(Function(kvp) kvp.Value IsNot Nothing).ToDictionary(Function(kvp) kvp.Key, Function(kvp) kvp.Value, StringComparer.OrdinalIgnoreCase)
```
Faz duas coisas ao mesmo tempo:
1. Reconstrói o dicionário como case-insensitive (`StringComparer.OrdinalIgnoreCase`) — resolve o `KeyNotFoundException` de `BenefitsAdmin` independente de a fila mandar camelCase ou PascalCase.
2. Remove chaves com valor `null` — expôs um SEGUNDO bug pré-existente na lib: o guard `Not ContainsKey("MedicalDeductibleReset")` (linha ~775-777 da lib) só testa ausência de chave, não valor nulo; como o campo real `medicalDeductibleReset` quase sempre vem `null`, e antes o `ContainsKey` case-sensitive nunca achava a chave (mascarando o bug), depois do fix de case-insensitivity o `ContainsKey` passou a achar a chave com valor `null` e o `.ToString()` subsequente quebrava com `NullReferenceException` (mensagem: "Can not assign ... to 'out_MedicalDeductibleReset'"). Remover chaves nulas no Assign resolve os dois de uma vez, sem tocar a lib.

**Teste E2E no Staging (2026-07-13):** item recriado na fila `Anthem_CO_GroupSubmission_NewPlan` (Staging, folder `Benefits`) com os dados EXATOS da Produção (Eras Group Consulting LLC, camelCase preservado, não a versão "bonita" da CLI) — 3 iterações:
1. Sem fix: reproduziu `KeyNotFoundException: 'BenefitsAdmin'` — confirma causa raiz.
2. Com fix v1 (só case-insensitive): passou do BenefitsAdmin, quebrou em `MedicalDeductibleReset` — expôs o 2º bug.
3. Com fix v2 (case-insensitive + drop nulls): `ProcessQueueItem` terminou com sucesso, fluxo seguiu até `CheckDataEligibility`, que falhou com `BusinessRuleException: "Order is no longer in Automation Queue"` — esperado (dado de teste é cópia de pedido real que não existe mais aberto no Salesforce de Staging), não é bug técnico. **Job terminou limpo (`Main execution ended with success`), sem fault.**

**Validação:** `uip rpa validate` limpo no arquivo editado; `uip rpa build` com os mesmos 51 erros pré-existentes (`UI-DBP-006`, confirmado via `git stash` que já existiam antes da mudança).

**Segundo item de teste, validado E2E via Studio (2026-07-13→14):** outro item Failed real de Produção na mesma fila com o mesmo erro `KeyNotFoundException: 'BenefitsAdmin'` — Expo Group, LLC (CO), CarrierOrderID `a0mR700000FOx4lIAD`, Reference `3faf0db7-e75d-4206-b4ba-637c4d738307`. Replicado (SpecificContent idêntico) na fila Staging `Anthem_CO_GroupSubmission_NewPlan` (folder key `b9457890-c55f-45ae-92e1-7cdd17291ef7`) — Id `2464990178`, UniqueKey `04cc72fe-1936-4c30-b9a8-e6aceafce89e`, Reference `3faf0db7-e75d-4206-b4ba-637c4d738307-BT74235-retest`. Rodado manualmente via Studio (jobId `9dcc5f60-3783-4a72-a3f5-d54450c81d68`): `ProcessQueueItem` passou limpo (sem `BenefitsAdmin`/`MedicalDeductibleReset`), fluxo seguiu até `CheckDataEligibility` → `BusinessRuleException: "Order is no longer in Automation Queue"` (esperado, mesmo padrão do 1º teste — dado copiado de pedido real já fechado no Salesforce Staging). `Main execution ended with success`, sem fault técnico. **Segunda confirmação independente (empresa diferente) de que o fix resolve o bug real.**

**Publicado + PR aberta (2026-07-14):** package `2.0.2` (`Anthem_CO_GroupSubmission_NewPlan`) gerado via `uip rpa pack --skip-analyze` (os erros UI-DBP-006 são pré-existentes, confirmados via git stash, não relacionados ao fix) e enviado ao feed do Orchestrator Staging; process binding (Key `D023361F-A8DE-4A31-A001-B8509819B1E9`, folder `Benefits`) atualizado via `uip or processes update-version` para `2.0.2`. PR #2932 aberta contra `develop`: https://github.com/Gusto/biztech-uipath-rpa/pull/2932.

**Jira comentado (2026-07-14):** comentário no BT-74235 cobrindo causa raiz, fix e bump de versão, com link da PR #2932.

**Ticket original CONCLUÍDO (2026-07-14):** PR #2932 aprovada, **merged e publicada em produção** (comentário do próprio usuário no Jira: "PR Approved, merged and published to production, we will monitor to the next runs."). Não fica mais "pendente review" — está em prod.

---

## Follow-up 2026-07-15 (mesmo thread do Jira, novo pedido da Bri Boyer)

Bri comentou de novo no BT-74235 pedindo pra limpar a fila `Anthem_CO_GroupSubmission_NewPlan` em Produção — mostrava 16 itens em `New` no UiPath, mas só 2 pedidos válidos no Automation Queue do Salesforce.

**Causa raiz #2 encontrada (bug novo, não relacionado ao BenefitsAdmin):** `NullReferenceException` em `ProcessGustoCensus` (activity da Library `gan:ProcessGustoCensus`) — `out_EmployeeHomeStates` vinha nulo pra pedidos antigos, e o `ui:ForEachRow` logo depois (linha 372 do `ProcessLayer/ProcessTransaction.xaml`) quebrava sem checar. Como é `NullReferenceException` (erro de sistema), o ReFramework abortava o processo inteiro após 3 falhas consecutivas (`"The Process has Failed in the Process State for a consecutive number of times equal to 3"`) — travando a fila inteira, não só o item.

**Fix aplicado (só no processo, não na lib):** `If employeeHomeStates Is Nothing → Throw BusinessRuleException("No census data found for this order...")` inserido entre a activity `ProcessGustoCensus` e o `ForEachRow`. Converte o crash de sistema em falha de negócio por item — não aborta mais o processo, só marca aquele item como Failed e segue pro próximo. `validate`/`build` limpos (mesmos 51 erros pré-existentes de sempre).

**Validado ao vivo em Produção via Studio debug (2026-07-15):** rodou 5 transações seguidas sem nenhum `NullReferenceException` — todas bateram (corretamente) em `BusinessRuleException: "Order is no longer in Automation Queue"` no `CheckDataEligibility` (confirma que eram os pedidos obsoletos que a Bri mencionou). `Main execution ended with success` ao final, sem abort. **Fila confirmada limpa: 16 → 0 itens `New`** (os 2 itens legítimos e recentes foram processados normalmente pelo schedule ativo).

**Comentário postado no Jira (2026-07-15, comment id 4224088):** avisando a Bri que a fila está limpa (16→0 `New`) + pergunta sobre o Problema #2 abaixo (Phone/Email no CompanyInformation) — perguntando se é comportamento esperado ou novo do portal Anthem. Aguardando resposta dela.

**Pendente:** abrir ticket Jira novo pra esse bug do census (usuário disse que abriria depois).

### Problema novo #1 — race condition no Broker Search (Quoting), analisado mas não implementado
Em `ProcessLayer\Quoting\QuotingLicense&ContractValidation.xaml`: digita o broker em `LCBrokerTypeAhead` (type-ahead), manda `Send Hotkey Down` + `Send Hotkey Enter` pra selecionar a sugestão, e clica `Continue` **sem checar se a seleção realmente colou**. Se a lista de sugestões ainda não carregou quando o `Down` é mandado, o `Enter` só confirma texto livre (sem TIN vinculado) — o portal bloqueia com "Select a valid Broker TIN from the drop down list" e fica na mesma tela, mas o bot segue como se tivesse navegado. É isso que causava o `SelectorNotFoundException` no `GroupDetails.xaml` (Check 'Create a New Group Account' não existe na tela de Broker Search).
**Usuário ajustou manualmente no debug e passou desse ponto** — fix formal (checar mensagem de erro + retry da seleção do broker) ainda não foi escrito no código.

### Problema novo #2 — Phone/Email na tela CompanyInformation (Enrollment/EnrollNow), NÃO RESOLVIDO
Depois de passar do Broker Search, o robô avançou até `ProcessLayer\Enrollment\CompanyInformation.xaml` (página "EnrollNow"). Usuário reportou que a tela está exigindo preencher Phone e Email antes de avançar. **Confirmado por leitura completa do arquivo: esse XAML NUNCA preencheu Phone/Email** — só Type of Business, Date Business Established, Company Address, City, Billing Address, Organisation Type, chamber/cafeteria/ownership radios, e clica "Next". Isso é diferente do `GroupContactInformation.xaml` (fase de Quoting, tela anterior) que já preenche Phone/Email — mas é outra tela, outra fase.

Não foi possível confirmar visualmente os campos reais porque **duas tentativas de inspecionar via "Salvar página como .html" falharam** — os campos ficam dentro de um `IFRAME` (`parentid='ServiceCommunityTemplate'`, componente Salesforce Community/Anthem SG Quoting OmniScript) que um save simples de página não captura (nem em "Get a Quote.html" nem em "EnrollNow.html", nenhum teve pasta `_files` com o conteúdo do iframe). Ver [[feedback_anthem_iframe_html_save_unreliable]].

**Bloqueado esperando:** screenshot do usuário mostrando os campos exigidos, OU sessão de indicação ao vivo (`uia-configure-target`) com o Studio pausado no breakpoint — pra não inventar seletor sem ver o elemento real (regra do projeto).

**Mapeamento de campos confirmado pela Bri Boyer (Jira comment 4225630, 2026-07-15 13:08):** ela não tem certeza do comportamento anterior do bot, mas confirma que o time manual preenche esses campos hoje, e que o bot deve preencher:
- **Phone** ← `companyPhoneNumber`
- **Email** ← e-mail do `benefitsAdmin`

Isso desbloqueia a implementação (falta só o seletor real via inspeção ao vivo do iframe, não mais a definição de qual dado usar). Status do ticket BT-74235 no Jira: **Done** (o ticket original foi resolvido; os dois problemas novos ainda não têm ticket próprio — usuário disse que abriria depois).

**Comentário postado no BT-74235 (2026-07-16, comment id 4229013):** agradecendo a Bri e confirmando que o código NUNCA foi construído pra preencher Phone/Email nessa tela — não é regressão, é gap de escopo original. Tratado como enhancement; usuário vai abrir ticket Jira novo pra rastrear a implementação (Phone=companyPhoneNumber, Email=benefitsAdmin).

**Ticket novo aberto (2026-07-16): [[project_bt74343_anthem_co_phoneemail_enhancement]] — BT-74343**, status Jira "New", cobrindo o enhancement de Phone/Email no CompanyInformation. Usuário já avisou a Sri no Slack (grupo de dev) sobre a abertura, explicando que o gap não é regressão recente — só apareceu agora porque o bot não roda em produção há um tempo (ficou mascarado enquanto a fila estava travada/parada).

**Pendente:** implementar o fix do BT-74343 (falta inspecionar seletor real do iframe ao vivo antes de codar — Phone=companyPhoneNumber, Email=email do benefitsAdmin).

**Nota de infraestrutura:** `git fetch`/`curl` pra GitHub falhou com erro `schannel: failed to receive handshake, SSL/TLS connection failed` nesta sessão — falha de TLS no nível do sistema na VDI. Resolvido de vez com `git -c http.sslBackend=openssl` (fetch e push voltaram a funcionar direto, sem precisar do workaround via GitHub API) — detalhes em [[feedback_git_tls_schannel_fix]].

**How to apply:** ao resumir, checar se já foi publicado no Staging/PR aberto antes de assumir que falta trabalho de código — o fix já está pronto e validado E2E, só falta a parte de publicação/PR.

Related: [[project_bt73710_anthem_ca_newplan]] (fix original camelCase→PascalCase que causou essa regressão em CO), [[feedback_staging_queue_items.md]] (SpecificData raw vs SpecificContent cosmético da CLI — mesma lição confirmada aqui de forma ainda mais definitiva).
