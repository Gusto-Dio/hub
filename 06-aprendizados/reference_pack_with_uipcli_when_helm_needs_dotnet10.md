---
name: reference-pack-with-uipcli-when-helm-needs-dotnet10
description: "uip rpa pack falha na VDI (Helm >=1.203 exige .NET 10, só há 8.0); empacotar direto com uipcli.exe do cache do rpa-legacy-tool; cuidados (reescreve project.json, não usar sed -i em CRLF)"
metadata:
  node_type: memory
  type: reference
  originSessionId: 642af944-036e-406f-b5be-f2e2b8467841
  modified: 2026-10-20T16:18:56.583Z
---

`uip rpa pack` quebra nesta VDI: "You must install or update .NET" (Helm 1.203.2/1.204.0 exigem Microsoft.NETCore.App 10.0, instalado só 8.0.28; só o Helm 1.202.1 usa 8.0). `uip rpa-legacy pack` também falha (wrapper injeta `--orchestratorUrl` desconhecido pelo uipcli).

**O que funciona:** chamar o uipcli direto (é o que o Buildkite usa, .NET 8):
`~/.uipath/.cache/rpa-legacy-tool/<ver>/legacy-cli/tools/uipcli.exe package pack "<.../project.json>" -o <pasta> --traceLevel Warning`
Gera o .nupkg mesmo com ruído de `BadImageFormatException`/`FileLoadException` (DLLs nativas). Confirmar `<id>`/`<version>`/dependências com `unzip -p <pkg> "*.nuspec"`. Depois: lib → `uip or libraries upload --file`; processo → `uip or packages upload <file>`; rebind → `uip or processes update-version <ProcessKey GUID> --package-version X --folder-path Benefits` (precisa do Key, não do nome; aprovação explícita).

**Cuidados:**
- uipcli REESCREVE `project.json` do projeto empacotado (adicionou `robotVersion` e `includeOriginalXaml` na lib e foi parar na PR) e cria `.dll/.pdb/.xml` na pasta. Sempre `git checkout -- .` no worktree/ou restaurar project.json antes de commitar.
- `sed -i` em arquivo CRLF (project.json do repo) converte para LF e o diff vira arquivo inteiro; editar em bytes com Python (`/c/Python314/python.exe -I`) preservando CRLF.
- Classic `ui:GetText` NÃO existe nas libs Windows deste repo; usar `ui:GetValue` (padrão já usado, com ContinueOnError).
- Buildkite `check_dependency.sh` compara project.json x dependencylock.json raiz por string exata, mas é PULADO em projetos com `skipTests: ["update_dependency"]` (a maioria, inclusive FloridaBlue); não mexer no lock raiz sem checar o impacto.
- Ver [[feedback_local_nuget_cache_version_collision]] e [[feedback_uip_libraries_vs_packages_upload]].
