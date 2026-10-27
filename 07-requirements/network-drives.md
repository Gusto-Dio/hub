# Drives de rede (VDI antiga)

| Letra | Destino | Uso |
|---|---|---|
| U: | `\gustocloud.apporto\dfs\GSTO\Users\<user>\Documents` | Documents/Projects da VDI Porto (some com a VDI) |
| Z: | `\fs3-prd-aws.gustocorp.com\BizTech` | share BizTech: credenciais dos robôs, Locks/.breaker.json |

Na VM AWS: verificar com a TI o acesso ao share BizTech e a letra equivalente. Os caminhos dos Locks/creds usados pelos processos estão nos projetos e em `reference_login_circuit_breaker_locks_share`. Memórias com caminho `U:\Projects\...` são históricas.
