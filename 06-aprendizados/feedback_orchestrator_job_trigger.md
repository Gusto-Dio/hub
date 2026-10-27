---
name: feedback_orchestrator_job_trigger
description: "Sempre disparar jobs de teste via Orchestrator (uip or jobs start), nunca via uip rpa run que roda na VDI do dev"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: accb44e9-4d15-46eb-b2dd-da2c46890e3b
---

Sempre usar `uip or jobs start` para disparar jobs de teste no Staging. `uip rpa run` executa localmente na VDI do desenvolvedor (toma o controle da tela/Chrome), o que é disruptivo e errado para testes.

**Why:** `uip rpa run` roda no robot local (VDI do dev), interrompendo o trabalho ativo na tela. Jobs de teste devem rodar no robot de servidor (`USCOL1-ROBODV-1` no Staging).

**How to apply:**

1. Garantir que o process binding existe no Orchestrator com a versão correta:
   ```bash
   # Verificar versão atual
   uip or processes list --folder-path "Benefits" --output json | grep -A5 "Anthem_CA"
   
   # Se versão antiga: deletar e recriar COM O MESMO NOME — nunca criar com nome diferente
   uip or processes delete "<process-key>" --yes --output json
   uip or processes create --name "Anthem_CA_GroupSubmission_NewPlan" \
     --package-key "Anthem_CA_GroupSubmission_NewPlan" \
     --package-version "1.21.XX" --folder-path "Benefits" --output json
   # Delete pode falhar se o processo teve job rodando recentemente — aguardar e tentar de novo
   ```

2. Disparar o job:
   ```bash
   uip or jobs start "<process-key-GUID>" --folder-path "Benefits" --output json
   ```

3. Monitorar:
   ```bash
   # Poll até completar
   until uip or jobs get "<job-key>" --output json 2>/dev/null | grep -qE '"State": "(Successful|Faulted)"'; do sleep 20; done
   
   # Logs de login
   uip or jobs logs "<job-key>" --output json 2>&1 | grep -E "(Login|MFA|success|Error)"
   ```

**Fluxo Staging com nova versão de lib:**
1. `uip rpa pack` com `--skip-analyze` no diretório do processo → gera `.nupkg`
2. `uip or packages upload "<processo.nupkg>"` → publica no feed Staging
3. `uip or processes create --name "..._vXXtest" --package-version X.X.XX` → cria binding
4. `uip or jobs start "<process-key>"` → roda em `USCOL1-ROBODV-1`
