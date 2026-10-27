---
name: feedback_git_tls_schannel_fix
description: git fetch/push falha com "schannel: failed to receive handshake" na VDI — fix é trocar o backend TLS para openssl, não contornar segurança
metadata:
  node_type: memory
  type: feedback
  originSessionId: 54402a72-0c48-4a2e-91be-db3a5cf00620
---

`git fetch`/`git push` para `github.com` falham na VDI com `schannel: failed to receive handshake, SSL/TLS connection failed` — reproduzível também com `curl https://github.com` puro (falha no nível do stack TLS do Windows/schannel, não é config de proxy nem do git). `git config --get http.proxy`/`https.proxy` vêm vazios.

**Fix que funciona:** trocar o backend TLS do Git for Windows de `schannel` para `openssl` na chamada:
```bash
git -c http.sslBackend=openssl fetch origin develop
git -c http.sslBackend=openssl push -u origin <branch>
```
Isso resolveu fetch e push de forma limpa. **Não é um bypass de verificação de certificado** — só troca a biblioteca TLS usada, mantendo validação normal. É diferente (e preferível) do workaround antigo de [[feedback_check_dependencylock_before_pr]]-adjacent sessions que evitavam fetch usando só `mcp__githubgusto__get_commit` — com o backend openssl, fetch/push locais voltam a funcionar direto, então prefira isso primeiro.

**Ruído esperado, ignorar:** depois do fetch/push/commit pode aparecer `fatal: could not write multi-pack-index: Permission denied` + `error: failed to perform geometric repack` — é uma tarefa de manutenção/gc em background sem permissão de escrita num arquivo de índice, não afeta o resultado da operação principal (fetch/push/commit completam com sucesso mesmo com esse erro impresso depois).

**Why:** antes disso, sessões perdiam tempo contornando `git fetch` inteiramente (via GitHub API/MCP) sempre que precisavam sincronizar com `develop` antes de um PR — o que impede `git merge origin/develop` local e obriga a resolver staleness só no lado do GitHub.

**How to apply:** sempre que `git fetch`/`push`/`clone` falhar com erro de schannel/TLS nesta VDI, tentar primeiro `-c http.sslBackend=openssl` antes de qualquer workaround via API. Não usar `-c http.sslVerify=false` nem outra forma de desabilitar verificação de certificado — isso seria bypass de segurança, não fix de infra.
