---
name: feedback_staging_queue_items
description: "Regra para criar itens no Staging: sempre preservar o formato original dos nomes de campo do SpecificContent (Salesforce __c format)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 518b3570-5bc9-4143-8236-e3c53b00ac25
---

Ao criar ou recriar itens na fila do Staging via `uip or queue-items bulk-add`, sempre preservar os nomes dos campos exatamente como estão no SpecificData raw da Production — nunca adaptar ou converter os nomes.

**Why:** O processo acessa `in_TransactionItem.SpecificContent("Group_Number__c")` esperando o formato Salesforce com underscores e sufixo `__c`. Se os campos forem adicionados com qualquer outra capitalização (ex: `GroupNumberC`) ou estrutura diferente, o acesso ao dicionário falha com SysEx imediatamente, antes de o bot tocar no portal.

**Fontes de erro confirmadas nesta sessão:**
1. `SpecificContent` (S maiúsculo) → campo ignorado pelo bulk-add; SpecificContent fica vazio → falha em `Id`
2. `GroupNumberC` (camelCase, via cópia de listagem da CLI) → chave errada → falha em `Group_Number__c`

**How to apply:**
1. Sempre consultar o `SpecificData` (raw JSON) de um item de Production para obter os nomes exatos dos campos:
   ```bash
   uip or queue-items get <item-key> --folder-path "Benefits" --all-fields --output json | grep SpecificData
   # Retorna: {"DynamicProperties":{"Group_Number__c":"274487",...}}
   ```
2. No JSON do bulk-add, usar `specificContent` (lowercase 's') e chaves no formato exato do SpecificData:
   ```json
   [{"reference": "...", "priority": "Normal", "specificContent": {"Group_Number__c": "274487", ...}}]
   ```
3. Após adicionar, SEMPRE verificar o SpecificData do item criado no Staging antes de rodar o job.

**Lembrete [[uip_rpa_cli_reference]]:** a CLI exibe SpecificContent em camelCase na listagem (`GroupNumberC`), mas o armazenamento raw usa o formato original. Não copiar da listagem — copiar do `SpecificData`.

**Reincidiu em 2026-07-09 ([[project_bt74147_bcbs_tx_add_dependent]]):** usando `queue-items add` (não `bulk-add`) via `--specific-content`, copiei do campo `SpecificContent` do `queue-items get` (que a própria API/CLI devolve normalizado em PascalCase, ex: `CarrierOrderID`) em vez do `SpecificData.DynamicProperties` raw (camelCase, ex: `carrierOrderID`) — mesmo erro, ferramenta diferente (`add` em vez de `bulk-add`). Ou seja, a regra vale pra **qualquer comando** de criar/recriar item (`add`, `bulk-add`), e o campo `SpecificContent` do `get` NUNCA deve ser usado como fonte — é sempre uma view cosmética, mesmo com `--all-fields`. Fonte única de verdade: `SpecificData` (string JSON) → `DynamicProperties`.

**Checklist atualizado:**
1. `uip or queue-items get <key> --folder-key <key> --all-fields` → extrair só `SpecificData` (ignorar `SpecificContent` do resultado)
2. `JSON.parse(SpecificData).DynamicProperties` → esse é o payload correto pra `--specific-content`
3. Depois de criar em Staging, **buscar de volta com `--output-filter SpecificData`** (não `SpecificContent`) pra confirmar a casing antes de rodar o job — o `SpecificContent` do item recém-criado também volta em PascalCase mesmo quando o raw está certo, então não serve de confirmação.
