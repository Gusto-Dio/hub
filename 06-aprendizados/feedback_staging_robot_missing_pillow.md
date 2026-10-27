---
name: feedback_staging_robot_missing_pillow
description: Robô unattended de Staging (ROBODV1-PRD-AWS) não tem Pillow/PIL instalado — quebra qualquer TakeFullPageScreenshot e trava o job até timeout
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a75c34b6-0c48-41ed-82ae-039d50a60c8c
---

Jobs disparados via `uip or jobs start` no robô unattended de Staging (`ROBODV1-PRD-AWS`) falham com `ModuleNotFoundError: No module named 'PIL'` em `ScreenshotPostProcessing.py` sempre que o workflow chama `TakeFullPageScreenshot` (Gusto_Generic_Activities). O erro não é tratado de forma limpa — deixa o `NApplicationCard` em fault e o job acaba morto por timeout (`Robot.JobKilledTimeout`, ~3 min depois), em vez de falhar rápido.

**Why:** infra da máquina do robô, não do código do processo — Pillow não está instalado no Python dessa VM (diferente da minha VDI de dev, que já tem Pillow 12.2.0, ver [[feedback_python_vdi]]).

**How to apply:** Antes de testar em Staging qualquer processo que use `TakeFullPageScreenshot`/screenshot de erro, esperar esse tipo de falha nesse robô específico. Preferir testar via Studio Desktop/Assistant na própria VDI (ver [[feedback_local_debug_folder_binding]]) em vez de `uip or jobs start`, até esse robô ter Pillow instalado. Reportar esse gap de infra pra quem administra a máquina — não é algo pra corrigir em XAML.
