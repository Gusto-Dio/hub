---
name: feedback_dependencylock_strict_no_skip_since_oct_2026
description: "Desde 26-27/10/2026 (#3479/#3481/#3487) check_dependency.sh exige TODO projeto alterado = dependencylock.json, sem skipTests; PR de lib precisa alinhar todas as deps e bumpar o lock; deploy de Prod flaky com 0x80131509"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 49ca5381-00f6-470a-b509-dce9f7b7a4fa
  modified: 2026-10-27T18:34:33.233Z
---

Thomas Taylor removeu o opt-out (`skipTests: update_dependency` não vale mais; `settings.json` antigo continua com a chave mas o script ignora) e refrescou o lock (#3487: Generic_Activities 2.2.2, SalesForce 2.0.1, Excel [3.4.1], GSuite [3.11.10], Mail [2.10.10], WebAPI [2.5.2], System [26.6.0], etc.). Qualquer PR que altere um projeto (lib ou processo) falha no Buildkite se QUALQUER dependência dele divergir do lock, com comparação de string exata (inclui colchetes: `[2.0.15]` vs `2.0.15`). Descoberto no BT-77065 ([[project_bt77065_bsca_nhe_plan_selections_chrome_prompt]]).

**Why:** a lib Gusto_Benefits estava defasada em 7 dependências, então um fix de 1 linha (timeout) virou PR com alinhamento de deps (só project.json, sem XAML), padrão igual ao da #3592 (Gusto_Modern_Generic). Consumidores da lib passam a herdar Excel 3/Mail 2/GSuite 3 como mínimo; Thomas pediu teste completo do bot quando mexermos nele por ticket de suporte.

**How to apply:**
- Antes de abrir PR: comparar TODAS as deps do projeto com `dependencylock.json` do origin/develop (`jq` não existe na VDI; usar `C:\Python314\python.exe -I` com json). Não rodar `check_dependency.sh` local (depende de jq).
- PR de lib: bumpar projectVersion + a linha da lib no lock (`check_lock.sh`); PR do processo que a consome: repetir a MESMA linha do lock para passar sozinha (merge limpo, mudança idêntica) em vez de esperar a lib mergear.
- Editar project.json/lock em bytes (Python), preservar CRLF/BOM; git trata como binário (`git diff --text`).
- Branch de PR não empacota; só o deploy no develop (`deploy.ps1` com uipcli) acusa quebra. Deploy flaky: `FileLoadException ... 0x80131509` (race de assembly load no analisador/validação), no mesmo agente; Retry manual resolve (3ª tentativa da lib). Ordem do Retry: lib → conferir feed Prod → processo. Falha do processo antes da lib no feed = `Cannot create unknown type AddLogFields` (consequência). Ver [[feedback_buildkite_analyzer_race_intermittent]].
- Staging: versão já existente dá 409; subir versão maior. Commits/PRs: sem Co-Authored-By de IA ([[feedback_pr_no_claude_signature_no_tx_table]]).
