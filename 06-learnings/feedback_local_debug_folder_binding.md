---
name: feedback_local_debug_folder_binding
description: uip rpa run headless local debug falha com GetRobotCredential (Error 1101) — precisa rodar via Studio Desktop/Assistant
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a75c34b6-0c48-41ed-82ae-039d50a60c8c
---

`uip rpa run --file-path Main.xaml` (headless, via Studio-Helm) falha com **"A folder is required for this action. Error code: 1101"** em qualquer workflow que use `ui:GetRobotCredential` para buscar um Credential asset do Orchestrator.

**Why:** GetRobotCredential precisa resolver qual pasta do Orchestrator usar pra buscar o asset, e essa informação vem do vínculo robot-machine-to-folder configurado no Orchestrator — o `uip rpa run` headless não carrega esse contexto (não há flag de `--folder` disponível, nem `uip config` expõe essa chave). Também não tem permissão pra listar `uip orchestrator machines list` (403) pra confirmar o vínculo de outra forma.

**How to apply:** Quando o processo faz login em portal via credencial de Orchestrator e precisa ser testado localmente (não via robô do Orchestrator), abrir o **Studio Desktop/Assistant** manualmente na VDI e rodar o Debug lá — não tentar contornar via CLI headless. Rodar via robô real do Orchestrator (`uip or jobs start`) também é uma alternativa, mas cuidado com [[feedback_staging_robot_missing_pillow]] se o cenário depender de `TakeFullPageScreenshot`.

**Update (2026-07-09):** confirmado de forma reproduzível (2x) no BT-74133 — `uip rpa build "."` falha o projeto inteiro por erros de analyzer PRÉ-EXISTENTES (`UI-DBP-006` "Top level selector used outside scoped containers" em várias telas antigas, tratados como Error) ANTES de sequer chegar no erro 1101. Isso é **sistêmico**, não específico do BCBS_MA: testei também `Anthem_NewHireEnrollment` e ele falha o build pelos mesmos motivos. Ou seja, `uip rpa run`/`build` headless não funciona pra NENHUM desses processos legados com muita automação de UI, mesmo sem tocar em `GetRobotCredential`.

**Workaround pra build (não resolve o 1101):** `uip rpa build "." --skip-analyze` pula o gate de analyzer e compila normalmente (se não houver lock de `.local/install/*.dll` por Studio Desktop aberto — nesse caso fecha o Studio primeiro). Depois `uip rpa run --file-path "X.xaml" --skip-build` reaproveita esse build e roda de fato — mas qualquer `ui:GetRobotCredential` ainda cai no erro 1101, porque o host headless (`Studio.Helm`) não tem NENHUMA conexão de Orchestrator vinculada a pasta, nem por `uip login`, nem por robô local (chequei: não tem `UiRobot`/serviço de robot core rodando nesta VDI, só `UiPath RobotJS Service`).

**Mecanismo real que funciona sem GUI:** existe `uip rpa remote configure --folder-path <path> --machine <name>` + `uip rpa run --remote`, que aponta pra um robô unattended REAL já vinculado a uma pasta no Orchestrator (`uip orchestrator machines list --folder-path <path>` lista candidatos). Isso resolve o 1101 de verdade, mas usa um slot de robô de produção real — não é "grátis", precisa confirmação do usuário antes (mesma cautela de nunca rodar teste direto em Prod). No caso do BT-74133, o usuário preferiu rodar via Studio Desktop mesmo (mais rápido, zero pegada em infra compartilhada) — o log confirmou `robotName: "<user>@gusto.com-attended"`, ou seja, é um robô ATENDIDO ligado à sessão de Assistant do usuário no Studio, não um robô unattended nem uma config local do CLI.
