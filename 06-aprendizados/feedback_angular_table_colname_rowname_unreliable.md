---
name: feedback_angular_table_colname_rowname_unreliable
description: UiPath FuzzySelector (regardless of attributes used) is unreliable against Angular tables with comment-node placeholders; use a strict Selector (SearchSteps=Selector, FullSelectorArgument) with tableRow/tableCol index + InteractionMode=DebuggerApi instead
metadata:
  type: feedback
  originSessionId: fc2006b8-97b4-4993-82c5-23e7ef1bc824
  modified: 2026-09-10T21:44:04.884Z
---

**CONFIRMED FIX (2026-09-10, see [[project_bt75495_kaiser_delegate_account_login]] "RESOLVED" section):** it's not just `colName`/`rowName` that's unreliable — the `FuzzySelector` matching *engine itself* is unreliable against this class of Angular table, even after reconfiguring it to use `tableCol` (index-based) instead of name-based attributes. A FuzzySelector version with `aaname` + `tableCol` passed once (on `Kaiser_CA_MemberUpdates`) then failed 3x in a row on a second process (`Kaiser_CA_Terminations`) running the identical code — proving the earlier "pass" was luck, not a fix. The reliable fix was switching entirely to `SearchSteps="Selector"` (the **strict** engine, `FullSelectorArgument`, not fuzzy) with structural addressing (`tableRow`+`colName`+`tableCol`) plus `InteractionMode="DebuggerApi"`. When a click against an Angular table fails intermittently, don't stop at "fix the FuzzySelector's attributes" — switch off FuzzySelector entirely and use a strict selector instead.

Selectors that use `colName`/`rowName` (name-based table cell addressing) against an Angular-rendered `<table>` can fail intermittently or outright with "Could not find the UI element", even when the target row/column is visibly present on screen.

**Why:** Angular (ivy) renders tables with `<!---->` comment-node placeholders interspersed between real cells/rows (for `*ngIf`/`*ngFor` bookkeeping). This breaks UiPath's row/column-name inference, which counts/matches header and cell text positionally. A live re-capture of the same element on the same page will often produce a *different* selector than the original — e.g. `tableCol='<index>'` (positional) instead of `colName`/`rowName` (name-based) — because UiPath's own capture logic detects the same table-structure ambiguity and falls back to index addressing. But even a positional FuzzySelector still isn't reliable — only the strict engine was.

**Second layer:** even after switching to index-based (`tableCol`) addressing, a click on such a table can still fail to register reliably under the default `InteractionMode="Simulate"`. Switching to `InteractionMode="DebuggerApi"` (Chrome DevTools Protocol-level event dispatch) fixed it — Simulate's synthetic events apparently don't always trigger the Angular click handler on this kind of virtualized/comment-heavy row.

**How to apply:** When a selector against an HTML `<table>` fails with "Could not find the UI element" despite the row being visibly on screen (especially on Angular-heavy portals), don't just re-capture and assume the new selector alone will fix it:
1. Use `SearchSteps="Selector"` (strict engine, `FullSelectorArgument`) with `tableRow`/`tableCol` (index-based) addressing — not `FuzzySelector`, even a `FuzzySelector` using `tableCol`. If the row position is stable per-account (e.g., one fixed delegate per login), a hardcoded `tableRow` index captured live is fine and more reliable than trying to keep it generic.
2. Add `InteractionMode="DebuggerApi"` on the click activity — Simulate mode can silently fail to register against Angular click handlers even when the element is correctly located.
3. A selector that "worked" in an earlier test run is not proof it's reliable — this class of table can pass by luck on some runs and fail on others with the identical code (confirmed: `Kaiser_CA_MemberUpdates` appeared to work fine on the FuzzySelector version, then a different process running the same code failed 3x in a row before the underlying flakiness was traced properly).
