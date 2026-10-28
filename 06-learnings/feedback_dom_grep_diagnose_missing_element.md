---
name: feedback_dom_grep_diagnose_missing_element
description: Quando um seletor falha e os "closest matches" são semanticamente irrelevantes, salvar a página e grep no HTML cru (por atributo/testid, não por texto visível) encontra a causa raiz mais rápido que reler o XAML
metadata:
  type: feedback
  originSessionId: 64b75f28-88d6-466c-b81c-27e5ff57cf5f
  modified: 2026-08-22T00:27:59.045Z
---

Técnica usada com sucesso no BT-75006 (Oxford_GroupSubmissions_NewPlan): bot travava em
`Click 'Group Details'` (`aaname='Group Detailschevron_right'`), erro "Could not find the UI
element", com "closest matches" tipo `calendar_today`, `Import Quote`, `arrow_forward` — nenhum
com relação semântica ao que se esperava.

**Passo que resolveu:** pedir pro usuário salvar a página (Chrome "Salvar como... página
completa") no estado exato da falha, e eu (Claude) grep no HTML cru via Bash — não confiar em
"visualmente parece certo" nem no texto visível.

**Por quê funciona quando o texto visível não ajuda:** o Chrome "Salvar página completa" captura
o DOM já renderizado (JS incluso), não só o HTML do servidor — diferente de "view-source". Em
SPAs (React/Angular), o estado real de um controle (`checked=""`, classe `-checked-true`,
`data-testid="xToggle-...checkbox"`) está nos atributos do elemento, não necessariamente visível
na tela. `grep -c` simples por keyword (ex: "Group Details") retornando **zero** ocorrências é
o sinal mais forte de que o elemento genuinamente não existe no DOM — mais confiável que
inspecionar visualmente.

**Cuidado com arquivo em uma linha só:** páginas SPA salvas costumam vir com o body inteiro em
UMA linha gigante (megabytes). `grep -o` com byte-offset (`grep -iobP 'padrão'`) + `dd
if=arquivo bs=1 skip=<offset> count=N` pra extrair contexto ao redor funciona bem quando `git
diff`/`grep -A/-B` não ajudam (contexto de linha não existe numa linha única).

**Contraste com [[feedback_anthem_iframe_html_save_unreliable]]:** lá o "salvar página" falhava
porque os campos reais do Anthem/Salesforce Community ficam dentro de um IFRAME que o "salvar
página" do Chrome não captura. Aqui (portal UHC SAMx / Abyss design system) não há iframe, então
a técnica funcionou perfeitamente — **checar primeiro se há iframe antes de confiar 100% no
método**; se `grep -c '<iframe'` no arquivo salvo retornar > 0 e o conteúdo relevante estiver
dentro dele, essa abordagem não vai funcionar sem capturar o iframe separadamente.

**Como aplicar:** quando um seletor falha e os matches próximos não fazem sentido semântico,
antes de assumir "seletor desatualizado" ou reescrever a lógica de retry, pedir uma captura da
página no estado exato da falha e grep por: (1) o texto/label esperado (zero hits = elemento
realmente ausente), (2) `data-testid`/atributos de estado (`checked`, `aria-*`, `class` com
`-checked-` ou similar) dos controles vizinhos que alimentam a mesma seção/validação.
