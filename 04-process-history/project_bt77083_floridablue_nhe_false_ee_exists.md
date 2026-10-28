---
name: bt-77083-floridablue-nhe-false-ee-exists
description: "BT-77083 FloridaBlue_NewHireEnrollment \"EE already exists\" falso — causa, evidências e decisões (investigação 28/10, sem código ainda)"
metadata:
  node_type: memory
  type: project
  originSessionId: 44e9d774-c205-4ad3-a267-bd1f6aa56f9d
  modified: 2026-10-28T22:44:47.153Z
---

BT-77083 (28/10/2026, Dio assignee, "Project breakglass"): ~35% dos casos FloridaBlue NHE falham com "EE already exists on carrier portal". Investigação feita; **nenhum código alterado ainda**; planilha de tracking não tem a linha (aba só vai até ~BT-72xxx).

**Causa (provada):** 1ª tentativa faz Submit+Save com sucesso e morre depois, em `ProcessLayer\CompleteEnrollment.xaml` no `Type Into 'Search by Name,SSN...'` (seletor genérico `<webctrl tag='INPUT' />`, erro "UiElement is no longer valid"). Item vira Failed/Application; re-fila → `CheckIfEmployeeExists` (lib) acha o EE → BusinessRuleException "EE already exists" (ProcessTransaction.xaml ~535, antes de qualquer digitação).
- Dos 25 itens "1ª tentativa" que antecedem um EE-exists (200 itens da fila desde 02/10): 18 no TypeInto pós-Save, 4 em EnterCoverage `Click 'Health Plan'` (pré-Submit), 3 "target element is disabled" (pré-Submit). 8 dos 33 EE-exists sem irmão na janela.
- Provado via bucket "Transactional Screenshots" (folder Benefits, key 683a3ab3-…): o `<itemKey>/Error.png` desses itens é na verdade o PDF "Summary of Enrollment - Florida Blue" (jsPDF, "Submitted by … AGENT") → o Catch do ProcessTransaction sobe TODOS os arquivos da TempFolder pro mesmo destino Error.png e o PDF sobrescreve o screenshot de erro. PDFs dos itens já falhos ainda recuperáveis nesse caminho (útil pro Ops anexar à mão).

**Plano (aguardando OK do Dio pra implementar, branch BT-77083):** só lógica, sem novo mapeamento. Em CompleteEnrollment: tudo depois do `Click 'Save'` (Existing Employees + TypeInto) em RetryScope + TryCatch que só loga Warn; Submit e Save continuam fatais. Também: espera/checagem do PDF, screenshot/upload tolerantes, AutomationMessage indicando o que faltou, e upload por extensão (.png/.pdf) em vez de `idx=0`/mesmo destino. NÃO resolve: falhas pré-Submit (7/25, possível rascunho no portal — precisa olhar o portal), duplicatas reais, nem os 22 itens atuais (Ops verifica e anexa PDF).

**Status 28/10 (fim do dia):** v1.1 IMPLEMENTADA, NÃO commitada, na branch `BT-77083-floridablue-nhe-post-submit-tolerance` (de origin/develop 2a8d384c4e3, sem upstream). 4 mudanças em FloridaBlue_NewHireEnrollment: CompleteEnrollment.xaml (retry+TryCatch pós-Save, out_ConfirmationSearchOk), CollectDownloadedPdf.xaml (novo: espera PDF na raiz da TempFolder e move p/ `Temp\FloridaBlue_NHE\`), ProcessTransaction.xaml (reset da pasta por transação, upload por extensão, AutomationMessage), project.json 6.0.7→6.0.8 (Prod está em 6.0.7). Pack OK com uipcli (nupkg 6.0.8 gerado, expressions compiladas). Falta: teste em Staging (aprovação explícita; checar se 6.0.8 já existe lá), commit/PR (inglês, sem assinatura), comentário Jira. Não confirmado: onde o Chrome do robô salva o PDF (Preferences na máquina do robô).
**Pack nesta VM:** uipcli precisa das libs exatas; baixei Gusto_Benefits 1.559.46 e Gusto_Generic_Activities 2.2.3 (`uip or libraries download`) para `C:\Users\diogenesribei_gsto\local-nupk` (fonte local-nupkg). uipcli reescreve project.json e DELETA entry-points.json: sempre `git checkout --` neles e rebumpar versão em bytes (CRLF; `sed -i` quebra CRLF). Ver [[reference-pack-with-uipcli-when-helm-needs-dotnet10]].

**Status 28/10 (noite) — NO AR em Prod:** PR #3685 (v6.0.10) mergeada, mas o deploy foi bloqueado pelo check_dependency novo (#3686: bots só podem depender de Gusto_*; o bot pinava UiPath.WebAPI.Activities direto). PR #3689 (v6.0.11) removeu a dep direta (vem transitiva via Gusto_Benefits 1.559.46, mesma versão [2.5.2]); mergeada, build #15474 passou. Process `FloridaBlue_NewHireEnrollment` (Key 1BB3948D-7F72-4A52-B1DE-D0910B025C7F, folder Benefits) estava em 6.0.5 e foi rebindado pra 6.0.11 com aprovação do Dio. Jira comentado (simples, sem detalhe técnico). Falta só monitorar: no 1º enrollment novo checar no bucket Transactional Screenshots PDF e Error.png separados, e onde o Chrome do robô salva o PDF. Ops ainda verifica à mão os itens já falhos.

**Why:** queue FloridaBlue_NewHireEnrollment tem MaxNumberOfRetries=0; exceção não-BRE no Process → SystemError → reset de ambiente + relogin com espera de 11 min (MFA), o que também agrava outras falhas.
**How to apply:** ao implementar, ler Main/ProcessTransaction de novo; testar em Staging 3 itens + 1 com falha forçada do TypeInto seguido de um 2º item (SearchForGroup parte de qualquer página EnrollPoint e trata popup "Unsaved Changes"). Ver [[feedback-deskcheck-before-fix-statemachine]].
