---
name: feedback_staging_package_upload_no_process_no_effect_on_studio_tests
description: "uip or packages upload no feed do Staging não afeta testes feitos via Studio Desktop se não existir Orchestrator Process vinculado ao pacote"
metadata:
  type: feedback
  originSessionId: df12d3df-f597-49e1-bf20-223d6e140384
  modified: 2026-09-23T22:15:15.668Z
---

Ao publicar `Oxford_GroupSubmissions_NewPlan.1.55.15` no feed do Staging (BT-75952), procurei em todas as pastas do Staging (`uip or processes list --folder-key ...`) por um **Process** vinculado a esse pacote e não achei nenhum. Os 8 testes que validaram o fix já tinham sido feitos via **Studio Desktop** (debug attended), que lê a fila do Orchestrator direto pela API e roda o **source local do projeto** — nunca consome o `.nupkg` empacotado.

**Why:** existem dois caminhos completamente independentes pra "rodar" um processo:
1. **Studio Desktop / debug attended** — lê fila via API, executa o XAML fonte local. Não depende de pacote publicado nem de Process no Orchestrator.
2. **Orchestrator Job** (`uip or jobs start`) — precisa de um **Process** criado numa Folder, vinculado a uma versão específica do pacote publicado no feed daquele tenant.

Publicar no feed (`uip or packages upload`) sozinho não ativa nada nem cria o Process — é só o pacote sentado no feed, disponível pra alguém (ou o Buildkite) vincular depois.

**How to apply:** se os testes de validação de um fix foram feitos via Studio Desktop, o upload do pacote pro feed do Staging é só **preparação pro deploy futuro em Produção** (via Buildkite) — não valida nada novo e não precisa de um Process no Staging pra isso funcionar. Só criar um Process no Staging (`uip or processes create`) se alguém realmente precisar rodar via Orchestrator Job ali. Ver [[feedback_orchestrator_job_trigger]] pro padrão de trigger correto quando isso for necessário.
