---
name: feedback_python_vdi
description: Python na VDI está em C:\Python314\python.exe — não mais em Python311; Pillow instalado lá
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 73d91e88-c0a9-407a-b51f-40b52e563594
---

Python na VDI mudou de localização.

- Path documentado no CLAUDE.md (`C:\Users\diogenesribei_gsto\AppData\Local\Programs\Python\Python311\python.exe`) **não existe mais**
- Python real: `C:\Python314\python.exe`
- Pillow 12.2.0 instalado no Python 3.14 em 2026-06-29
- `python.cmd` em `C:\Windows\System32\` também não existe — mas UiPath encontra Python pelo PATH do sistema (`C:\Python314` está no PATH)

**Why:** VDI foi atualizado/reinstalado e o Python 3.11 foi substituído pelo 3.14.
**How to apply:** Usar `C:\Python314\python.exe` para instalar pacotes ou testar imports. Se UiPath não encontrar Python, verificar PATH do sistema antes de criar `python.cmd`.
