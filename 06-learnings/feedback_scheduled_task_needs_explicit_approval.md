---
name: feedback-scheduled-task-needs-explicit-approval
description: Criar Scheduled Task no Windows é bloqueada por padrão pelo classificador do modo automático
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ada11ec7-bcaa-4ad6-9c71-9a0b6068c186
  modified: 2026-09-22T14:21:50.486Z
---

Registrar uma Scheduled Task (`Register-ScheduledTask`, `schtasks /create`) é bloqueado pelo classificador do modo automático do Claude Code com o motivo "Unauthorized Persistence", mesmo sendo uma ação local, reversível e de baixo risco (ex.: recriar um shortcut perdido a cada login).

**Why:** Scheduled Tasks rodam automaticamente sem supervisão futura, então o modo automático trata isso como persistência que precisa de aprovação humana explícita, não como uma ação comum de arquivo.

**How to apply:** se a tarefa exigir uma Scheduled Task, avisar o usuário e pedir aprovação explícita antes (ou tentar e deixar o prompt de permissão aparecer). Não tentar contornar com métodos alternativos (ex. Run key do registro, pasta Startup) sem também avisar — a intenção do bloqueio é a mesma. Ver caso de uso em [[reference_claude_desktop_shortcut_selfheal]].
