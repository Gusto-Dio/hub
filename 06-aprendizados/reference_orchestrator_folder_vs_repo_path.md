---
name: reference_orchestrator_folder_vs_repo_path
description: Caminho do repo (CarrierAutomations) não é o mesmo folder do Orchestrator — verificar sempre antes de investigar jobs
metadata: 
  node_type: memory
  type: reference
  originSessionId: e52105d8-9adc-40e3-b153-2340b3c978d7
  modified: 2026-08-11T00:17:39.556Z
---

O caminho do repositório (`Processes/Benefits/CarrierAutomations/MemberSubmission/<Carrier>/...`) não corresponde 1:1 ao folder do Orchestrator. Confirmado em 2026-08-11 durante [[project_bt74849_beam_nhe_portal_fix]]: o processo `Beam_NewHireEnrollment_Modern` roda no folder raiz **`Benefits`** no Orchestrator (Production), não em `Benefits/CarrierAutomation` como o nome do repo sugeriria — `uip or jobs list --folder-key <CarrierAutomation>` retornava vazio (0 jobs, qualquer state, qualquer processo) para esse processo, enquanto `--folder-key <Benefits root>` trouxe o histórico completo de jobs faultando.

**Why:** o CLAUDE.md do projeto lista `Benefits/CarrierAutomation` como folder padrão dos processos de CarrierAutomations, mas isso não é garantido pra todo processo — a organização de pastas no Orchestrator pode divergir da estrutura de diretórios do repo.

**How to apply:** antes de assumir o folder do Orchestrator a partir do path do repo, confirmar com `uip or jobs list --folder-key <key> --process-name <nome> --limit 5` (sem state filter) primeiro. Se vier vazio, checar o folder raiz do carrier/produto (ex: `Benefits`) antes de concluir que não há jobs — resultado vazio nesse caso não é ausência, é folder errado.
