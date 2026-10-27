---
name: reference_deployps1_legacy_workflowcompiler_bug
description: ".buildkite/deploy.ps1 não consegue empacotar processos Legacy (targetFramework Legacy/schema 4.0) — WorkflowCompiler usado pelo UiPath.CLI.Windows moderno não suporta Legacy, só o UiPath.CLI.Windows.Legacy suporta"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9bf620e3-9272-4ed5-af38-9a6f9b4a01f4
  modified: 2026-09-03T21:14:56.081Z
---

`.buildkite/deploy.ps1` instala e usa só `UiPath.CLI.Windows` (uipcli moderno, pinado em `25.10.16`) pra empacotar TODO processo que mudou, Legacy ou Windows — o comentário no topo do arquivo diz "Handles both Legacy and Windows targetFramework projects in a single path", mas isso está desatualizado/errado: `package pack` do uipcli moderno roda por baixo dos panos via `UiPath.WorkflowCompiler.dll`, e o `WorkflowCompiler` **não suporta projetos Legacy** (erro: `System.InvalidOperationException: WorkflowCompiler does not support Legacy projects`).

Confirmado via doc oficial: projetos "Windows - Legacy" precisam do `UiPath.CLI.Windows.Legacy` (`uipcli-legacy.exe` / `uip rpa-legacy package pack`), uma ferramenta CLI separada — não dá pra "consertar" passando flag no pack normal.

**Impacto:** qualquer processo Legacy que precise de um bump de versão + republish em Prod vai falhar o Buildkite nesse exato ponto. Não é um bug introduzido por uma PR específica — é estrutural do pipeline atual.

**Como o time historicamente contornou isso:** não corrigindo o `deploy.ps1` — migrando cada processo Legacy individualmente pra `targetFramework: Windows` (ver [[project_bt75456_uhc_packetcollection_legacy_windows_migration]] pro padrão exato do diff). Dezenas de commits `[BT-XXXXX] <Processo> - Legacy to Windows Migration` já fizeram isso em quase todo `Advising/Packet_Collection` e vários outros.

**Stragglers conhecidos ainda em Legacy** (em 2026-09-03, na pasta `Advising/Packet_Collection`): `UnitedHealthcare_SAM` (sendo migrado no BT-75456) e `Kaiser_CA`. Provavelmente existem outros Legacy fora dessa pasta que só vão descobrir o problema quando precisarem de um bump de versão.

**Não fizemos ainda:** reportar/corrigir o `deploy.ps1` em si (adicionar detecção de `targetFramework` e rotear pro `UiPath.CLI.Windows.Legacy` quando for Legacy) — decisão consciente de não tocar infra compartilhada sob pressão de incidente; migrar processo por processo é mais contido, mas o bug de fundo continua lá pra próxima pessoa que precisar bumpar um Legacy.
