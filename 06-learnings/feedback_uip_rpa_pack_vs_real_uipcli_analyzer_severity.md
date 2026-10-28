---
name: feedback_uip_rpa_pack_vs_real_uipcli_analyzer_severity
description: uip rpa pack (CLI local) trata ST-SEC-008 (SecureString fora do scope) como Error e falha o pack; a ferramenta real que o Buildkite usa (UiPath.CLI.Windows / uipcli) trata a mesma regra como Warning e builda limpo — não confiar no "uip rpa pack" pra decidir se o Buildkite vai quebrar
metadata:
  type: feedback
  originSessionId: 54ae0ab1-a529-41ce-ae99-64267fd4f71b
  modified: 2026-09-23T22:14:49.348Z
---

Ao validar um PR do BT-75733 antes de abrir, `uip rpa pack` falhou com `Analyzer error: ST-SEC-008 (Error): SecureString variable used outside of the creation scope` em várias activities do `Kaiser_GroupSubmissions_MemberLevel_Modern`. Tentei `--governance-file-type Default` pra descartar policy do AutomationOps — mesmo erro. Testei também empacotando o `develop` sem meu diff (via `git stash -u`) — o mesmo erro aparece, confirmando que é **pré-existente**, não algo introduzido pelo fix.

Só depois de instalar a ferramenta real que o `.buildkite/deploy.ps1` usa (`dotnet tool install UiPath.CLI.Windows --version 25.10.16`) e rodar `uipcli package pack` com os mesmos argumentos do pipeline, confirmei: **`ST-SEC-008` aparece só como `Warning` lá, não `Error`** — o pack termina com exit code 0 e gera o `.nupkg` normalmente. `uip rpa pack` (a CLI Node local) usa um motor de análise diferente/mais estrito que não reflete a severidade real usada pelo Studio/uipcli.

**How to apply:**
1. Se `uip rpa pack` falhar num processo antigo/legado com um analyzer error que não faz sentido pro diff atual, primeiro testar se ele já existe em `develop` sem o seu diff (`git stash -u` + pack + `git stash pop`) — se sim, é pré-existente, não seu.
2. Pra saber com certeza se vai quebrar o Buildkite, instalar a ferramenta real (`dotnet tool install UiPath.CLI.Windows --version <versão do deploy.ps1> --tool-path <caminho curto>`) e rodar `uipcli package pack <project.json> -o <dir> -v <versão>` — essa é a fonte de verdade, não `uip rpa pack`.
3. **Instalar em caminho curto** (ex: `C:\tmp_uipcli`), não dentro do scratchpad de sessão — o `SolutionPackager` interno do uipcli monta um caminho profundo (`...\.store\uipath.cli.windows\<versão>\...\SolutionPackager\Tools\workflowcompiler`) que passa do limite do Windows (`PathTooLongException`) se a raiz já for longa.
4. **`uipcli package pack` deleta o `entry-points.json` da pasta do projeto depois de empacotar** (comportamento real da ferramenta, não bug) — se esse arquivo estiver commitado, `git restore` ele depois de cada pack local antes de comitar/seguir trabalhando.
5. **Atalho mais rápido que instalar o uipcli real:** se já confirmou via `uip rpa build` (baseline diff com/sem o diff) que os analyzer errors são pré-existentes, basta empacotar com `uip rpa pack ... --skip-analyze` — pula a etapa de análise inteira e gera o `.nupkg` direto. Usado no BT-75952 (Oxford_GroupSubmissions_NewPlan) pra publicar no Staging sem precisar instalar o `UiPath.CLI.Windows` — mais rápido quando a única meta é ter o pacote, não re-confirmar a severidade real.
