---
name: uip_rpa_cli_reference
description: "Referência completa do uip rpa CLI — debug, build, analyze, activities. Preferir CLI ao Studio para produtividade."
metadata: 
  node_type: memory
  type: reference
  originSessionId: f9d79d3f-cc2a-4bea-82b2-3a81948a6fbc
  modified: 2026-09-11T16:52:43.959Z
---

# uip rpa CLI — Referência completa

**Regra:** sempre preferir CLI ao Studio para ações que podem ser feitas sem clicar.

---

## Debug

### Iniciar sessão de debug
```powershell
uip rpa debug start --file-path "ProcessLayer\InitAllApplications.xaml" --log-level Trace
# --skip-build: pula rebuild se os arquivos não mudaram (mais rápido em reruns)
# --input-arguments key=value: passa argumentos de entrada
# --profiling: coleta tempo por atividade (requer perfil Studio Develop)
```

### Iniciar a partir de uma atividade específica (pula tudo antes)
```powershell
uip rpa debug start-from-here --input-variables "varName=expression" --input-arguments "argName=value"
# Útil para pular a fase de login e começar direto em uma página de enrollment
# --input-variables: seed de variáveis no escopo da atividade focada
# --input-arguments: seed de argumentos no escopo
```

### Breakpoints
```powershell
uip rpa debug toggle-breakpoint   # coloca/remove na atividade focada no Studio
# Cicla: enabled → disabled → none
```

### Navegação passo a passo
```powershell
uip rpa debug step-over      # executa atividade atual e para na próxima
uip rpa debug step-into      # entra dentro da atividade (InvokeWorkflow, lib activity)
uip rpa debug step-out       # sai do escopo atual
uip rpa debug continue       # continua até o próximo breakpoint
uip rpa debug break          # pausa na próxima atividade executada
uip rpa debug restart-from-top  # reinicia a sessão do início
uip rpa debug resume         # resume após estado suspenso
```

### Tratamento de exceções durante debug
```powershell
uip rpa debug continue-retry       # retenta a atividade que falhou (útil para seletor instável)
uip rpa debug continue-ignore      # ignora a exceção e continua
```

### Cancelar execução
```powershell
uip rpa execution cancel   # cancela debug ou run ativo
```

---

## Build & Analyze

### Build (compilar o projeto)
```powershell
uip rpa build "Processes\Benefits\CarrierAutomations\GroupSubmission\Anthem\Anthem_CA_GroupSubmission_NewPlan"
# --skip-analyze: pula workflow analyzer (mais rápido)
# --feed-url <url>: adiciona feed NuGet extra
```

### Analyze (workflow analyzer)
```powershell
uip rpa analyze "Processes\...\Anthem_CA_GroupSubmission_NewPlan"
# Retorna violações de regras do analyzer configurado no projeto
```

### Listar regras do analyzer ativas
```powershell
uip rpa analyzer-rules list
# Mostra id, severity, scope, descrição — rodar ANTES de editar XAMLs
```

---

## Activities

### Buscar uma activity pelo nome
```powershell
uip rpa activities find --query "Click"
uip rpa activities find --query "UiElementExists"
# Retorna metadata, className, tags
```

### Ver XAML padrão de uma activity (como seria ao dropar no designer)
```powershell
uip rpa activities get-default-xaml --activity-class-name "UiPath.Core.Activities.Click"
# Útil para construir XAML correto sem abrir o Studio
```

---

## Files

### Diff visual entre dois arquivos XAML
```powershell
uip rpa files diff "file1.xaml" "file2.xaml"
# Abre janela no Studio com as diferenças destacadas
```

---

## Orchestrator (uip or)

### Jobs
```powershell
uip orchestrator jobs list --process-name "Anthem_CA_GroupSubmission_NewPlan" --state Faulted --folder-path "Benefits" --limit 10
uip orchestrator jobs logs "<job-guid>"         # logs de um job específico
uip orchestrator jobs get "<job-guid>"          # detalhes + error message completa
uip orchestrator jobs history "<job-guid>"      # timeline de estados do job
```

### Folders (para descobrir o folder-path correto)
```powershell
uip orchestrator folders list
# Retorna Name, Path, Key de todas as pastas acessíveis
```

---

## Publicar processo no Orchestrator (sem Studio Desktop)

Fluxo completo via CLI — funciona no VDI mesmo sem dotnet SDK:

```powershell
# 1. Trocar para o tenant correto
uip login tenant set Staging    # ou Production

# 2. Pack local (gera .nupkg)
uip rpa pack "<process-dir>" "<output-dir>" --output json

# 3. Upload do package para o Orchestrator
uip or packages upload "<package.nupkg>" --output json

# 4. Atualizar o processo existente para a nova versão
#    (obter o process-key via: uip or processes list --folder-key <id>)
uip or processes update-version <process-key> --package-version <version> --output json

# 5. Disparar job
uip or jobs start <process-key> --folder-path "Benefits" --output json
```

**IMPORTANTE — Tenant IDs (Staging):**
- Benefits folder-key: `48382`
- Jobs list para Staging Benefits: `uip or processes list --folder-key 48382`

---

## Queue Items — Armadilha: formato das chaves no bulk-add

**PROBLEMA CONFIRMADO:** `uip or queue-items bulk-add` **NÃO preserva** os nomes de campo originais do SpecificContent. Quando você copia itens via API e passa o `SpecificContent` como JSON, as chaves são armazenadas exatamente como você passou — mas se você usar as chaves que a CLI retorna na listagem (`GroupNumberC`), elas ficam diferentes das chaves Salesforce originais (`Group_Number__c`) que o processo espera.

**Regra:** Sempre usar as chaves no formato Salesforce (`Field_Name__c`) ao adicionar itens via `bulk-add`. Para confirmar o formato correto, consultar o campo `SpecificData` (raw JSON) de um item de Produção, não o `SpecificContent` (que a CLI converte para camelCase na exibição).

```powershell
# Correto: chaves Salesforce originais
uip or queue-items get <item-key> --folder-path "Benefits" --all-fields --output json | grep "SpecificData"
# Mostra: {"DynamicProperties":{"Group_Number__c":"274487",...}}

# Errado: usar chaves que a CLI exibe no SpecificContent
# SpecificContent.GroupNumberC → ERRADO para o processo
# SpecificContent.Group_Number__c → CORRETO para o processo
```

**Sintaxe do bulk-add:**
```bash
# queue-name é argumento posicional (não --queue-name)
# items vão via --queue-items como JSON string (não --items-file)
ITEMS=$(cat items.json)
uip or queue-items bulk-add "QUEUE_NAME" --folder-path "Benefits" --queue-items "$ITEMS" --output json
```

**Robot logs via OData (Staging):**
```bash
TOKEN=$(grep UIPATH_ACCESS_TOKEN ~/.uipath/.auth | cut -d= -f2-)
# JobKey é Edm.Guid — sem aspas, sem prefixo 'guid'
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "X-UIPATH-OrganizationUnitId: 48382" \
  "https://cloud.uipath.com/gustoinc/Staging/orchestrator_/odata/RobotLogs?\$filter=JobKey%20eq%2084d50549-489b-4af0-854c-93cd0b80b75d&\$orderby=TimeStamp%20asc&\$select=TimeStamp,Level,Message"
```

---

## uip rpa pack — Regras para evitar falhas

### Pré-requisito: dotnet no PATH
`uip rpa pack` depende de `dotnet.exe`. Se não estiver no PATH padrão:
```powershell
$env:PATH = "C:\Program Files\dotnet;" + $env:PATH
```

### Pack de processo que usa lib customizada
O packer resolve as dependências da lib via NuGet do **tenant conectado**. Para que o pack funcione:
1. A versão da lib referenciada em `project.json` deve estar no feed do tenant **antes** de rodar o pack
2. Se a lib ainda não está no feed → upload dela primeiro, depois pack do processo
3. Se mesmo com upload o pack falha: verificar se o NuGet cache local tem a versão correta em `~/.nuget/packages/<lib-name>/<version>/`

### Sintaxe correta
```powershell
# Pack de processo
uip rpa pack "<process-dir>" "<output-dir>" --output json

# Run de arquivo específico (sem rodar o Main.xaml)
uip rpa run --file-path "MyHelper.xaml"  # executar do diretório do projeto

# Upload de lib para o feed
uip orchestrator libraries upload --file "Lib.nupkg"  # --file é obrigatório (não positional)

# Upload de processo para o Orchestrator
uip orchestrator packages upload "<process.nupkg>"   # positional, sem --file
```

### Estratégia quando pack do processo falha com "Cannot create unknown type"
- O packer não encontra a lib → o tenant conectado não tem a versão da lib no feed
- Solução: `uip login tenant set <Tenant>` para o tenant que TEM a lib → pack → upload do processo
- Alternativa: popular manualmente o cache NuGet local com o nupkg extraído como .zip

---

## Armadilha: `uip` CLI não conecta em Production por padrão

**PROBLEMA CONFIRMADO (BT-74025):** Apesar do CLAUDE.md dizer que a conexão padrão do `uip` CLI é Production, a sessão pode estar logada em **Staging** por padrão/residual de uso anterior. Isso causa falsos negativos: job GUIDs e queue IDs citados em tickets Jira (ex.: link do Orchestrator com `tid=`/`fid=`) retornam 404 / não encontrados porque a busca está rodando no tenant errado.

**Sempre confirmar antes de investigar produção:**
```powershell
uip login status
# Verificar campo "Tenant": deve ser "Production" para investigar tickets de produção
```

Se estiver em "Staging", trocar antes de puxar logs/queue items reais do ticket:
```powershell
uip login tenant set Production   # investigar
# ...
uip login tenant set Staging      # trocar de volta ao terminar (postura padrão segura — nunca disparar jobs em Production)
```

**Por quê importa:** sem essa checagem, dá pra gastar muito tempo tentando bater os IDs do ticket (queue ID, job GUID) contra dados de um tenant que nem é o certo — os dois tenants (`Production`, `Staging`) têm estrutura de pastas idêntica (`Benefits`, `Benefits/CarrierAutomation`), então os resultados "parecem" plausíveis mesmo estando no tenant errado.

---

## Armadilhas: `uip or queues list` / `uip or triggers list`

**`-n/--name` + `--folder-path` juntos podem dar "HTTP 400: Invalid OData query options"** mesmo com nome exato de fila existente (confirmado 2026-09-11, filas `Anthem_Packets`/`BCBS_IL_Packets`/`BCBS_MA_Packets`). Workaround: listar tudo sem filtro (`--limit 200`) e usar Grep local no output, em vez de confiar no `-n`.
```powershell
uip orchestrator queues list --folder-path "Benefits" --limit 200
# depois: grep "\"Name\": \"BCBS_MA_Packets\"" -A 8 no output salvo
```

**`--folder-path` pode falhar com "Folder does not exist or the user does not have access" mesmo pra pasta visível em `uip or folders list`** (confirmado com a pasta "Automation Ops" — nome com espaço). Nesse caso, usar `--folder-key` com o GUID retornado por `uip or folders list`.
```powershell
uip orchestrator folders list --limit 200   # pega o Key da pasta
uip orchestrator triggers list --type time --folder-key "<key>" -n "BCBS_MA"
```

**`--all-folders` é mutuamente exclusivo com `--folder-path`/`--folder-key`** — nem sempre dá erro claro (`queues list` recusa a combinação, mas sozinho com `-n` ainda pode falhar com o erro de OData acima).

---

## Fluxo de debug recomendado para BT-73710

1. Abrir o XAML no Studio (foco na atividade onde quer o break)
2. `uip rpa debug toggle-breakpoint` — coloca o break via CLI
3. `uip rpa debug start --file-path "Main.xaml" --log-level Trace` — inicia debug
4. Quando pausar no break: inspecionar variáveis no Studio
5. `uip rpa debug step-over` / `step-into` para navegar
6. Se seletor falhar: `uip rpa debug continue-retry` para retentar sem reiniciar tudo
7. `uip rpa execution cancel` para abortar quando terminar
