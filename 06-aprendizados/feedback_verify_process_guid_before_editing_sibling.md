---
name: feedback_verify_process_guid_before_editing_sibling
description: "Quando existem processos irmãos com nome parecido (ex UnitedHealthcare_SAM vs SAMx), confirmar o GUID (ProjectKey do Orchestrator = projectId do project.json) ANTES de editar/migrar, não confiar em similaridade de nome/descrição"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9bf620e3-9272-4ed5-af38-9a6f9b4a01f4
  modified: 2026-09-10T04:09:56.329Z
---

Antes de editar/migrar um processo pra corrigir um fault de Produção, quando existe mais de um projeto com nome parecido na mesma pasta (ex: `UnitedHealthcare_SAM` vs `UnitedHealthcare_SAMx`, ou qualquer par Legacy/variante), **confirmar por GUID exato**, não por nome/descrição parecida:

```powershell
uip or processes list --folder-path "Benefits" --name "<parte do nome>" --all-fields
# olhar o campo "ProjectKey" do Release
```
Depois comparar esse `ProjectKey` contra o `"projectId"` no `project.json` de CADA candidato até achar o match exato (`git show origin/develop:".../project.json" | grep projectId`).

**Por quê:** No BT-75456, migrei (project.json + AddLogFields fix + KillAllProcesses fix, 2 commits) o `UnitedHealthcare_SAMx` inteiro achando que era o processo certo — nome, descrição genérica ("collects renewal packets...") e estrutura de pastas pareciam bater. Só depois de comparar o `ProjectKey` do Orchestrator (`ef990c5b-...`) contra o `projectId` de cada pasta descobri que o processo real era o `UnitedHealthcare_SAM` (sem "x") — tive que reverter os 2 commits e refazer tudo no processo certo.

**Como aplicar:** sempre que o nome do Package/Process no Orchestrator (`ProcessKey`) não tiver sufixo óbvio que combine 1:1 com uma única pasta do repo (ex: "Advising_UHC_PacketCollection" sem "SAMx"), tratar como ambíguo e verificar por GUID antes de tocar em qualquer arquivo. Descrição/nome do bot batendo "parecido" NÃO é confirmação suficiente.

Ver também [[project_bt75456_uhc_packetcollection_legacy_windows_migration]].

**Mesma armadilha, mecanismo diferente:** no BT-75495, o nome parecido era entre duas **libs** (`Gusto_Benefits_Kaiser_CA` standalone vs `Gusto_Benefits.Kaiser_CA.Generic` dentro da mega-lib), ambas expondo uma activity `LoginToKaiser` via o mesmo prefixo XAML `gkg:`. A verificação nesse caso não é GUID — é confirmar o `xmlns:gkg="clr-namespace:...;assembly=..."` real declarado no arquivo consumidor antes de editar. Ver [[project_bt75495_kaiser_delegate_account_login]].
