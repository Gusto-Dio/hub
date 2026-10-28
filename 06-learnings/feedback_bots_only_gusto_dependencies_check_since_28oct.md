---
name: feedback_bots_only_gusto_dependencies_check_since_28oct
description: "Desde 28/10/2026 (#3686) check_dependency.sh rejeita bot (Processes/) com dep fora de Gusto_* e projeto Legacy; só aparece no build do develop pós-merge se a PR passou antes; fix = remover dep direta (vem transitiva da lib)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: a28d5d67-9e3c-42bc-8e5b-6f2ce8646c5b
  modified: 2026-10-28T22:59:24.991Z
---

Em 28/10/2026 a PR #3686 adicionou ao `check_dependency.sh` duas regras: (1) todo projeto em `Processes/` só pode ter dependências `Gusto_*` no project.json (UiPath.* e terceiros chegam via lib); `Libraries/` é isento; (2) `targetFramework` tem que ser Windows ou Portable (sem a chave = Legacy = rejeitado). Complementa [[feedback_dependencylock_strict_no_skip_since_oct_2026]].

**Why:** a PR #3685 do BT-77083 (FloridaBlue_NewHireEnrollment) passou no CI e foi mergeada, mas o build do develop (#15472) falhou no check_dependency porque o bot pinava `UiPath.WebAPI.Activities` direto; o `deploy.ps1` ficou `waiting_failed` e a 6.0.10 nunca saiu. A #3686 tinha entrado ~35 min antes e o CI da PR rodou com o script antigo. Resolvido na #3689 (v6.0.11).

**How to apply:**
- Antes de abrir PR de bot: `git fetch` e ler o `.buildkite/check_dependency.sh` do `origin/develop` (usar `MSYS_NO_PATHCONV=1` com `git show origin/develop:.buildkite/...` no Git Bash, senão o path é mutilado). Meu checkout local pode estar com o script velho.
- Se o bot tem dep fora de Gusto_*: NÃO apagar às cegas. Conferir se o XAML usa (ex.: `ui:DeserializeJson` = WebAPI) e se alguma lib Gusto_ consumida já a declara na mesma versão (`unzip -p <lib>.nupkg '*.nuspec'`; libs em `C:\Users\diogenesribei_gsto\local-nupk`). Se sim, remove a linha do project.json + bump de projectVersion; se não, adicionar à lib primeiro.
- Se a PR mergeada e o build do develop falhar: o deploy não roda e Prod não muda; abrir PR de correção com versão +1 (check_version exige bump).
- `jq` não existe na VM: validar as regras com Python. Pack com uipcli precisa de caminho ABSOLUTO do project.json (relativo duplica o path) e reescreve project.json (robotVersion/includeOriginalXaml) e apaga entry-points.json: restaurar com `git checkout --` e reaplicar a edição em bytes ([[reference_pack_with_uipcli_when_helm_needs_dotnet10]]).
