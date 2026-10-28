---
name: reference-uip-queue-items-cli-gotchas
description: "uip or queue-items — sem comando de retry, delete exige --yes e é bloqueado pelo auto mode, como recolocar item com formato idêntico (SpecificData bruto), e armadilhas de listagem"
metadata:
  node_type: memory
  type: reference
  originSessionId: 830837ca-d071-494d-82af-c67ea5973aff
  modified: 2026-10-22T01:06:10.904Z
---

Descoberto no BT-76973 ([[project_bt76973_bcbs_ma_popup_blocked_chrome_closed]]):

- **Não existe retry na CLI** (`uip or queue-items` só tem add, bulk-add, update, delete, get, list, set-reviewer etc.). `update` não muda status. Retry de item Failed = botão Retry na UI do Orchestrator (gera item novo `New`; o original continua listado como Failed). Item InProgress/Abandoned sem Failed: recolocar com `add`.
- **Recolocar com formato exato:** `list --all-fields` traz `SpecificData` (string JSON) com `DynamicProperties` = chaves reais gravadas. Montar o payload a partir dele (`json.dumps(..., ensure_ascii=True, separators=(",", ":"))`, valores já são strings planas, `CaseData` como string), gravar em arquivo sem BOM e passar `--specific-content "$(cat arquivo)"` em Bash. Passar também `--reference`, `--priority`, `--due-date` do original. Conferir depois comparando `DynamicProperties` do novo vs original. Ver [[feedback_uip_queue_items_get_repascalizes_keys]] (o `get` reescreve a caixa das chaves; por isso não usar).
- **`delete` exige `-y/--yes`** (sem ela responde "Confirmation required... cannot be undone"). O auto mode do Claude Code BLOQUEIA o delete em Produção: o Dio rodou o script via `! bash <script>`. Item InProgress pode ser apagado (Orchestrator aceitou).
- **Listagem:** `--limit` máx 100, `--sort-by "Id desc"`, `--folder-path Benefits`, `--queue-name` exato; `jobs list --process-name` não precisa folder com `--all-folders`; `processes list` não tem `--search` (usar `--output-filter` JMESPath). `--output-filter` com objeto/`length` às vezes não imprime; mais seguro salvar o JSON e agregar com `C:\Python314\python.exe -I`.
- **Gotcha de script:** arquivo de lista gerado por Python no Windows sai com CRLF; `tr -d '\r'` antes de `read` no Bash, senão o caminho do payload vira inexistente e a CLI recusa `--specific-content` vazio (nada é criado).
- Item preso: InProgress de job faultado vira Abandoned ~24h depois (início 06:01 → fim 06:06 do dia seguinte).
- `jobs list --state Running` com saída vazia no grep não prova que não há job; confirmar com `jobs get <key>` quando a conta importa.
