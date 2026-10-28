---
name: project_bt73710_anthem_ca_newplan
description: "BT-73710 — Anthem_CA_GroupSubmission_NewPlan: lib 1.552.8 + processo 1.21.11 — MFA While_5 fix (Ahsen request) validado no Staging, PRs #2856 e #2857 aguardando merge"
metadata: 
  node_type: memory
  type: project
  originSessionId: e4e451d4-792e-4866-a618-1b16f75c5a04
---

BT-73710 é uma falha de produção no `Anthem_CA_GroupSubmission_NewPlan`.

## Root causes identificados e corrigidos

1. Portal mudou whitespace no botão "Log In" — corrigido em lib 1.527.3 (wildcard `*Log In*`)
2. Processo era Legacy framework — lib migrou para Windows em 1.536.1, causando TryCatch cancellation errors → **corrigido neste ticket**
3. `ProcessQueueItem.xaml` manteve chaves camelCase em `SpecificContent` — Windows é case-sensitive → `benefitsAdmin` falha quando fila envia `BenefitsAdmin` → **corrigido neste ticket**
4. `LoginToAnthemBroker.xaml` usava `DIV aaname='Book of Business'` (500ms) para detectar login bem-sucedido — elemento não existe mais no portal → **corrigido neste ticket**

## Branches e PRs

- **Lib branch:** `BT-73710-Gusto-Benefits-lib-fix` → PR [#2856](https://github.com/Gusto/biztech-uipath-rpa/pull/2856)
- **Process branch:** `BT-73710-Anthem-CA-GroupSubmission-NewPlan-fix` → PR [#2857](https://github.com/Gusto/biztech-uipath-rpa/pull/2857)
- **Ordem de merge obrigatória:** #2856 primeiro (Buildkite precisa publicar a lib antes de validar o processo)

## Versões finais

- Lib `Gusto_Benefits`: **1.552.8** (publicado no Staging, PR #2856 pendente para develop)
- Processo `Anthem_CA_GroupSubmission_NewPlan`: **1.21.11** (publicado no Staging, PR #2857 pendente para develop)
- `dependencylock.json` raiz: atualizado para `1.552.7` (incluso no PR #2856 — `dependencylock` não bumpa a cada versão intermediária)

## O que foi feito (lib branch)

- **28 SpecificContent keys:** camelCase → PascalCase em `ProcessQueueItem.xaml`
- **`ratingStructure` → `RatingStructure`:** confirmado com item real da fila
- **`medicalDeductibleReset`:** `IsNothing(SpecificContent(...))` → `Not SpecificContent.ContainsKey(...)` (Windows joga KeyNotFoundException em chave ausente)
- **Login validation redesign em `LoginToAnthemBroker.xaml` (1.552.5):**
  - Adicionado `menuVisible` — `UiElementExists` positivo no menu do dashboard (`aria-role='button' parentid='mnuTools' innertext='*Tools*Resources*'`, `TimeoutMS="5000"`, `WaitForReady="INTERACTIVE"`)
  - `If [menuVisible] → loginSuccess=True` — detecção de login por sinal positivo, não ausência de erros
  - `accountLocked` movido para dentro de `Sequence "Check MFA or Direct Login"`, antes de `If Direct Login Success`
  - Removido `Element Exists 'MFA Required (confirm)'` duplicado
- **MFA race condition fix (1.552.6):**
  - `accessCodeRequired` (`Element Exists 'Sign In: Access Code'`) timeout: 500ms → 5000ms
  - Com 500ms o elemento de MFA não era detectado antes do timeout, causando o fallback negativo a disparar e pular o fluxo de MFA
- **Remoção do fallback negativo (1.552.7):**
  - Removido bloco `If Direct Login Success` de `LoginToAnthemBroker.xaml`
  - Login success agora requer exclusivamente `menuVisible=True` (sinal positivo)
  - Elimina o caminho de falso positivo quando a página carrega lentamente
- **`dependencylock.json`:** atualizado de `1.552.4` para `1.552.7`

## O que foi feito (process branch)

- Migração Legacy → Windows framework
- Correções de validação (activities removidas, entry-points.json, KillAllProcesses.xaml)
- Lib bumped para 1.552.6

## Testes realizados no Staging

| Job ID | Versão | Cenário | Resultado |
|---|---|---|---|
| 6ee4e418 | 1.21.7 | Login direto | Pass (falhou em Excel por falta de licença na VM — infra) |
| 510704211 | 1.21.8 | Login direto (sem MFA) | Pass — `success:True` via `menuVisible` |
| 510721099 | 1.21.9 | Login com MFA | Pass — `accessCode:True` → Gmail → `success:True` |
| 510742607 | 1.21.10 | Login direto (sem fallback) | Pass — BusinessException esperada ("Order is no longer in Automation Queue"), 38s |
| d490e073 | 1.21.11 | Login com MFA (Ahsen fix) | Pass — `Post-MFA poll ended — loginFailed:False success:True` via `menuVisible` em `While_5` |

## Checklist

- [x] Login fix implementado e testado
- [x] camelCase → PascalCase corrigido
- [x] Feedback da revisão (ahsennur + fresh-eyes) endereçado
- [x] Lib 1.552.6 publicada no Staging
- [x] Processo 1.21.9 publicado no Staging
- [x] dependencylock.json atualizado
- [x] PR lib #2856 comentado com resultados dos testes
- [x] PR processo #2857 criado
- [x] Fresh-eyes Majors endereçados (lib 1.552.7): fallback removido + dependencylock corrigido
- [x] Lib 1.552.7 e processo 1.21.10 testados no Staging (job 510742607 — Successful)
- [x] Ahsen fix implementado (lib 1.552.8): While_5 MFA path usa menuVisible selector em UiElementExists_14
- [x] Lib 1.552.8 + processo 1.21.11 testados no Staging (job d490e073 — Successful, MFA pass)
- [x] Branches pushed para origin
- [x] PRs #2856 e #2857 atualizados com títulos e tabela de testes completa (5 jobs)
- [x] Oscar avisado
- [x] PR #2856 aprovado e mergeado ✅
- [x] PR #2857 mergeado ✅ (2026-06-24 20:32 UTC)

**Why:** Portal login + Windows migration scope; library case bug exposed by Windows case-sensitivity.
**How to apply:** CO process terá o mesmo problema quando migrar para Windows — a fix da lib cobre ambos.
