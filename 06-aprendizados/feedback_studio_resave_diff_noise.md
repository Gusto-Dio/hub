---
name: feedback_studio_resave_diff_noise
description: Quando o usuário debuga/edita no Studio Desktop e o arquivo XAML fica com diff gigante (milhares de linhas), é reordenação de atributos/ViewState do Studio, não mudança real — reverter pro HEAD e reaplicar só a mudança real via Edit
metadata:
  type: feedback
  originSessionId: 64b75f28-88d6-466c-b81c-27e5ff57cf5f
  modified: 2026-08-22T00:28:22.983Z
---

Descoberto no BT-75006: depois de o usuário debugar `EnterCompanyInfo.xaml` no Studio Desktop
(adicionando `DelayBefore`/`DelayAfter` numa única activity), o `git diff` mostrou **6528 linhas
alteradas** no arquivo inteiro (478KB → 481KB). Isso NÃO significa que o usuário editou o arquivo
inteiro — é o Studio reordenando atributos de virtualmente toda activity ao salvar (ex:
`AlterIfDisabled="{x:Null}" DelayMS="{x:Null}" ClickType=...` muda de ordem em relação a
`sap2010:Annotation.AnnotationText=...`) mais recálculo de `HintSize`/`ShapeSize` em cascata.

**Como isolar a mudança real em vez de aceitar o diff gigante:**
1. `git diff -a` (força modo texto, contorna o BOM UTF-8 que faz o git tratar XAML como binário)
2. Localizar o `IdRef` da activity que você sabe que foi editada (ex: `NCheck_4`) e grepar
   direto por ele no diff — cada activity XAML fica numa linha só, então a linha antes/depois
   aparece pareada e a mudança real salta aos olhos mesmo em arquivo grande.
3. Se o diff do arquivo inteiro for majoritariamente ruído: `git checkout -- <arquivo>` (reverte
   pro HEAD) e reaplicar a mudança real manualmente via Edit, comparando old_string/new_string
   exatos — produz um diff final de poucas linhas em vez de milhares, muito melhor pra review de
   PR.
4. Cuidado: **não reverta sem confirmar primeiro que a única mudança real já foi capturada** —
   ler o diff completo (ou normalizado, ver abaixo) antes de descartar.

**Truque pra normalizar antes de comparar** (quando o grep direto não é suficiente porque o
arquivo tem BOM+CRLF que confunde até o `diff` linha-a-linha): stripar BOM (`sed
's/\xEF\xBB\xBF//'`) e CRLF (`tr -d '\r'`) de ambas as versões antes de diffar — sem isso, `diff`
pode mostrar pares idênticos como "removido+adicionado" só por causa de `\r` invisível.

**Como aplicar:** sempre que um debug session no Studio Desktop terminar e for hora de comitar,
checar `git diff --stat` de TODOS os arquivos tocados (não só o que você esperava editar — no
BT-75006, `Main.xaml` e `project.json` também apareceram modificados sem eu ter tocado neles).
`Main.xaml` era 100% ruído de ViewState (revertido). `project.json` tinha um bump de dependência
legítimo (Studio auto-resolveu pra bater com `dependencylock.json`) — esse foi mantido. Nunca
assumir que "arquivo apareceu no `git status`" = "precisa reverter" nem = "precisa comitar";
sempre inspecionar o diff real primeiro.
