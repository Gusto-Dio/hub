---
name: project_bt75456_uhc_packetcollection_legacy_windows_migration
description: BT-75456 — Advising_UHC_PacketCollection faultando (FileNotFoundException no Google service-account key); causa raiz é package Legacy travado no deploy.ps1; migração Legacy->Windows em andamento no UnitedHealthcare_SAM (sem x)
metadata: 
  node_type: memory
  type: project
  originSessionId: 9bf620e3-9272-4ed5-af38-9a6f9b4a01f4
  modified: 2026-09-03T21:14:26.622Z
---

**BT-75456** (auto-criado, 2026-09-03): `Advising_UHC_PacketCollection` faultou em Prod após 9 falhas consecutivas em `ProcessTransaction` — `System.IO.FileNotFoundException: Key file not found at path: \\usscl1-fs-3\BizTech\biztech-natural-language-proc-9c3edf9e7ef4.json`.

## Causa raiz
- PR #3228 (Oscar, 26/08) migrou paths de file-server (`KeyPath`/`GoogleDriveKeyPath`/lock folder) de hardcoded em `Data/config.json` pra Orchestrator Assets, por causa da migração de infra `usscl1-fs-3` → `fs3-prd-aws.gustocorp.com` (cutover 30/08). O Asset em Prod já está correto (aponta pro host novo).
- O Process em Orchestrator (folder `Benefits`) está pinado num package **v1.17.11 publicado em abril/2026** — bem antes do PR #3228 — porque o **`deploy.ps1` não consegue empacotar projetos Legacy**: `UiPath.CLI.Windows` (uipcli moderno) usa `WorkflowCompiler` internamente pro `package pack`, e `WorkflowCompiler` **não suporta projetos Legacy/schema 4.0** (confirmado via doc oficial UiPath — projetos Windows-Legacy precisam do `UiPath.CLI.Windows.Legacy` / `uip rpa-legacy package`, uma ferramenta separada). Isso bloqueia republish de QUALQUER processo Legacy que precise de bump de versão, não é bug introduzido por nós.
- Ver [[feedback_verify_process_guid_before_editing_sibling]] — inicialmente migrei o processo ERRADO (`UnitedHealthcare_SAMx`) por engano; o processo real ligado ao Orchestrator (`ProjectKey ef990c5b-b558-40f4-b443-49f08456baf7`) é `UnitedHealthcare_SAM` (sem "x"). Revertido e refeito no certo.

## Descoberta importante: padrão já estabelecido no repo
Migração Legacy→Windows não é a reescrita grande tipo "_Modern" — é um padrão pequeno e MECÂNICO, já feito repetidamente pra quase todo `Advising/Packet_Collection`:
```
Anthem, Beam, BCBS_IL, BlueShieldCA, BCBS_TX, Kaiser, Guardian, QueueBuilder → já Windows
UnitedHealthcare_SAM, Kaiser_CA → únicos ainda Legacy (stragglers/resquício)
```
Diff típico (confirmado comparando commit de migração do Anthem antes/depois): `project.json` (flip `targetFramework` + bump `Gusto_Benefits`→~1.55x + `Gusto_Generic_Activities`→2.1.1 + version bump) + `project.uiproj` (+6 linhas) + os XAMLs do ProcessLayer recompilados (binário, tamanho muda pouco).

## Erros de build headless (`uip rpa build`) encontrados e corrigidos (mesmos 2 em SAMx e SAM)
1. **`Please provide at least one field`** — `ui:AddLogFields.Fields` com `<scg:Dictionary x:TypeArguments="x:String, InArgument" />` (dict vazio) — o analyzer moderno rejeita, o Legacy não validava. Fix: trocar por `<InArgument x:TypeArguments="x:String" x:Key="Argument1" />` (placeholder que o Anthem já usa). CUIDADO: NÃO confundir com `ui:SetTransactionStatus.Analytics`/`.Output`, que usam o MESMO dict vazio mas isso É tolerado (não tocar).
2. **`InvokeWorkflowFile` apontando pra `ProcessLayer\KillAllProcesses.xaml`** que nunca existiu no projeto (bug latente antigo, só quebra no catch de `CloseAllApplications.xaml`). Fix: trocar por `<g:KillAllProcesses .../>` (activity da lib `Gusto_Generic_Activities`, mesmo fix usado no `Beam_Terminations` na migração dele).
3. **`UI-DBP-006` (Top level selector used outside scoped containers)** — não é mecânico, precisa Studio + teste ao vivo (embrulhar em scope de app/browser). Feito pelo usuário no Studio (converteu pra `NClick`/`NApplicationCard`).

## Status atual (2026-09-03, sessão em andamento)
- Branch: `BT-75456-UHC-PacketCollection-republish-stale-package`.
- **PR #3286 já foi MERGEADO em develop** — mas continha só o bump de versão simples (commit `bc3235c23d6`), decidido insuficiente depois que descobrimos o bug do `deploy.ps1`. Quando a migração terminar, precisa **abrir PR NOVO** (o #3286 não reabre).
- `UnitedHealthcare_SAM` (correto): `project.json` migrado (Windows, deps bumpadas), `AddLogFields` e `KillAllProcesses` corrigidos, commitado (`ac6907bc904`) e pushado.
- Usuário testando ao vivo no Studio (attended, robotVersion 26.0.191). Achados do teste ao vivo:
  - Falha em `Click 'SAMx One (All states...)'` dentro do menu `primarynav` — suspeita de falta de delay/wait entre abrir o menu e clicar no submenu (sem `Element Exists`/delay entre os dois `NClick`).
  - Depois, falha em `ui:Click "Click 'Renewal Dashboard'..."` — activity CLÁSSICA (não NClick) com selector próprio de 2 níveis `<html htmlwindowname='SAMX' title='UHC-SAMx'/><webctrl aaname='Renewal Dashboard'.../>`. Erro mostra closest-match 67% com `title='UHC-SAMx'` idêntico mas `htmlwindowname=''` (vazio) em vez de `'SAMX'` — ou seja, **o robô ACHA a janela certa**, só o atributo `htmlwindowname` do seletor está desatualizado (o portal não seta mais esse window.name). Não é erro de navegação, é seletor com atributo obsoleto — fix: remover/soltar `htmlwindowname='SAMX'` do seletor.
- `UnitedHealthcare_SAMx` (processo errado, revertido): fica pra trás como candidato a migração futura também (é Legacy, mas não está relacionado a esse ticket).

## Pendências
- Terminar fix dos seletores ao vivo no `UnitedHealthcare_SAM` (menu timing + htmlwindowname).
- `uip rpa build` limpo.
- `slo.yaml`: `UnitedHealthcare_SAM` (e `Kaiser_CA`) são os únicos sem — não bloqueia Buildkite (`slo_validate.sh` trata como opt-in), fica pra depois, fora do escopo imediato (usuário pediu foco no objetivo principal).
- Abrir PR novo quando o build/teste ao vivo fechar limpo.
- Considerar reportar o bug do `deploy.ps1`/`WorkflowCompiler`+Legacy pro time que mantém o Buildkite (afeta qualquer processo Legacy no repo, não só esse).

Ver também [[feedback_verify_process_guid_before_editing_sibling]], [[feedback_check_version_bump_before_pr]], [[feedback_deskcheck_before_fix_statemachine]].
