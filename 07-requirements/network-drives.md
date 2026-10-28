# Network drives

| Letter | Target | Use |
|---|---|---|
| U: (AWS VM, current) | `\\fs3-prd-aws.gustocorp.com\BizTech` | BizTech share: robot credentials, Locks/.breaker.json. Mapped by Dio on 2026-10-28 (the choice of `U:` instead of `Z:` was deliberate) |
| U: (old Porto VDI, gone) | `\\gustocloud.apporto\dfs\GSTO\Users\<user>\Documents` | personal Documents/Projects of the old VDI |
| Z: (old Porto VDI, gone) | `\\fs3-prd-aws.gustocorp.com\BizTech` | same BizTech share, old letter |

Mapping command: `net use U: \\fs3-prd-aws.gustocorp.com\BizTech /persistent:yes`. Errors: `5` = access denied (ask IT for access), `53` = path not found (network).

Lock/credential paths used by the processes are in the projects and in `reference_login_circuit_breaker_locks_share`. Memories that mention `U:\Projects\...` or `Z:` are historical; if a script fails to find Locks or credentials, check whether it assumes the old letter.
