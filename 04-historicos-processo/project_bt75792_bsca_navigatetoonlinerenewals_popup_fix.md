---
name: project_bt75792_bsca_navigatetoonlinerenewals_popup_fix
description: BT-75792 — fix consolidado DENTRO da lib Gusto_Benefits (1.559.34); os 5 processos voltaram a chamar a activity compilada, sem cópia local dedicada
metadata: 
  node_type: memory
  type: project
  originSessionId: 607f5403-0bc6-44ab-903b-90fd1a84ee7b
  modified: 2026-09-17T10:16:48.094Z
---

BT-75792: todos os processos BSCA (`BSCA_GroupSubmissions_GroupLevel`, `BSCA_GroupSubmissions_MemberLevel`, `BSCA_NewHireEnrollment`, `BSCA_Terminations`, `BSCA_MemberUpdates`) faultavam em Production desde 12/09 com "Enrollment modal did not appear after Shop & Enroll click.", lançado por `Gusto_Benefits.BSCA.Generic.NavigateToOnlineRenewals` (lib compartilhada).

**Root cause em cadeia:**
1. A troca pra RPA Delegate Account ([[project_bt75657_bsca_delegate_account_login]]) mudou o timing: o popup "leaving Blue Shield of CA" passou a aparecer logo depois do clique em "Shop & Enroll" (não mais no final do fluxo).
2. A checagem do botão "Continue" do modal de enrollment (`modalVisible`) usava seletor relativo, restrito à aba do `BrowserScope` original — mas "Shop & Enroll" abre uma aba **nova**, então a checagem nunca achava o botão lá.
3. Timeout de 5000ms era curto pra esperar o carregamento da página pós-redirect externo.
4. Depois de corrigir 1-3 na lib, ficou claro que o modal "Continue" **não é confiável nem determinístico** — em 4 dos 5 processos ele simplesmente nunca aparece (fluxo segue direto pra outro passo, ex: NHE tem seu próprio `NavigateToEnrollment` depois), e no Terminations foi intermitente (passou uma vez com a lib pura, falhou de novo no reteste).

**Fix intermediário (abandonado):** cada um dos 5 processos ganhou uma cópia LOCAL de `NavigateToOnlineRenewals.xaml` (`ProcessLayer\NavigateToOnlineRenewals.xaml`), invocada via `InvokeWorkflowFile` em vez da activity compilada da lib. Na cópia local: o `Throw "Enrollment modal did not appear..."` foi comentado (`ui:CommentOut`) e os dois `Click` de "Continue" ganharam `ContinueOnError="True"`.

**Consolidação final (pedido do ahsennur no review):** ela comentou em #3340-#3344 pedindo pra usar a activity compilada da lib em vez de manter workflow local duplicado por processo. Resultado:
- A mesma correção (Throw dentro de `ui:CommentOut` + `ContinueOnError="True"` nos dois Click 'Continue') foi portada de volta pra dentro de `Libraries/Gusto_Benefits/BSCA/Generic/NavigateToOnlineRenewals.xaml`.
- Lib bumpada pra `1.559.34`, empacotada com `uip rpa pack --skip-analyze` (a lib tem ~144 erros de analyzer pré-existentes e não relacionados, em arquivos nunca tocados — `--skip-analyze` é necessário pra empacotar) e publicada em Staging via `uip or libraries upload`.
- Os 5 processos foram revertidos: removida a cópia local `ProcessLayer\NavigateToOnlineRenewals.xaml`, `InitAllApplications.xaml` volta a chamar a activity compilada da lib, `project.json` com floor `Gusto_Benefits` em `1.559.34`, `dependencylock.json` raiz também bumpado.

**PRs finais contra `develop`:**
- #3339 — MERGEADA (fix de seletor/timeout na lib, sem a consolidação ainda) — foi mergeada pelo usuário no meio do trabalho, antes do commit de consolidação subir; branch remota foi deletada no merge.
- #3345 — NOVA PR (aberta em cima do que já foi mergeado em #3339): consolidação `ui:CommentOut` + `ContinueOnError` na lib, versão `1.559.34`.
- #3340 (NHE), #3341 (GroupLevel), #3342 (MemberLevel), #3343 (MemberUpdates), #3344 (Terminations) — todas atualizadas com um novo commit revertendo pra activity compilada + bump de floor pra `1.559.34`. Todas passam `validate` e `build --skip-analyze` limpos; falta confirmação ao vivo em Staging pós-consolidação.

Explicação do approach (por que começou por processo, depois consolidou) foi redigida para enviar à ahsennur separadamente (Slack/comentário), com aprovação do usuário antes de enviar.

**Why:** entender que esse modal é intrinsecamente não-confiável no portal BSCA evita reintroduzir um `Throw` obrigatório nele no futuro — qualquer nova automação BSCA que passe por "Shop & Enroll" deve tratar esse "Continue" como opcional desde o início. A decisão de onde colocar esse tratamento (lib vs. processo) depende do reviewer/convenção do time — nesse caso a lib compartilhada venceu por reduzir duplicação entre os 5 processos.

**How to apply:** se aparecer erro parecido em outro processo BSCA (ex: `Advising_BSCA_PacketCollection` ou algo novo), preferir tratar na lib compartilhada direto (Throw em `ui:CommentOut` + `ContinueOnError` nos clicks), não criar cópia local por processo — isso já gerou retrabalho e um pedido de correção no review. Ver também [[feedback_gmail_via_filter_breaks_after_sender_change]] e [[feedback_navigatetobookofbusiness_redundant_after_delegate_switch]] pra outros efeitos colaterais conhecidos da troca de Delegate Account.
