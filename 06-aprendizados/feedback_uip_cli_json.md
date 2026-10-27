---
name: feedback_uip_cli_json
description: Como passar JSON complexo para o uip CLI no Windows sem erro de splitting ou BOM
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f9d79d3f-cc2a-4bea-82b2-3a81948a6fbc
---

Passar JSON complexo (com espaços, aspas aninhadas) para `uip orchestrator queue-items add --specific-content` falha em PowerShell e Bash quando feito inline — o shell quebra o JSON nos espaços.

**Why:** PowerShell 5.1 faz word-splitting mesmo com splatting `@args`; Bash falha se o arquivo tem BOM UTF-8.

**How to apply:**
1. Construir o JSON em PowerShell com `ConvertTo-Json -Compress`
2. Escrever em arquivo temporário **sem BOM**: `[System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))`
3. No Bash, ler e passar: `JSON=$(cat "$tmpFile"); uip ... --specific-content "$JSON"`

Exemplo completo:
```powershell
$json = $hashtable | ConvertTo-Json -Compress -Depth 5
[System.IO.File]::WriteAllText("$env:TEMP\payload.json", $json, [System.Text.UTF8Encoding]::new($false))
```
```bash
JSON=$(cat "C:/Users/.../AppData/Local/Temp/2/payload.json")
uip orchestrator queue-items add "QueueName" --folder-path "Folder" --specific-content "$JSON"
```
