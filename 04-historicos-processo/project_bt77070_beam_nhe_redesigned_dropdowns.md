---
name: project_bt77070_beam_nhe_redesigned_dropdowns
description: "BT-77070 Beam_NewHireEnrollment_Modern faulting since 2026-10-20 — Beam redesigned the add-employee form (dropdowns became div role=combobox); TICKET FECHADO 2026-10-27, PR #3591 merged, Prod on v1.6.10"
metadata:
  node_type: memory
  type: project
  originSessionId: 11f8ad41-d179-4b91-a441-087cb3686cd2
  modified: 2026-10-27T01:11:30.112Z
---

BT-77070 (opened 2026-10-26 by Tammy Borders, "Beam NHE login/MFA?"): NOT a login problem. Root cause = Beam redesigned the add-employee form around 2026-10-19/20; dropdowns went from INPUT + LI options to `div role="combobox"` (Base UI, dynamic ids like `base-ui-_r_70_`, never use them in selectors). Jobs faulted daily from 2026-10-20 on `Click sex assigned at birth: Target or anchors attributes has changed`; the IMAP/access-code timeouts only appeared after the 6-consecutive-exception restart. Last good job 2026-10-19; no process commits 2026-08-28..2026-10-20.

**Fix:** PR #3591 (branch `BT-77070-beam-nhe-sex-assigned-selector`, v1.6.10, Gusto-Dio). Replaced menu-click + option-click pairs with `NSelectItem` for Sex (Female/Male branches), State (`Item=[state]`, two-letter codes, list incl. WI/WY), Employment type (`Item` = case-insensitive match of `in_EmploymentType` against Full-time/Part-time/Contract, falls back to raw value; the OLD click already used in_EmploymentType via FuzzySelector, I wrongly hardcoded Full-time first), EnterCoverage Reason for addition (selector now has the label; the old generic `combobox INPUT` matched a date field) and Validate coverages Filter status (after `Click 'Coverages'`, `Click 'filter'`/`Click 'ALL'` removed). Selectors that worked: `<webctrl tag='DIV' aria-role='combobox' innertext='<Label>*' ... />`; State uses `visibleinnertext='State*'` (or `aria-labelledby='addressState-label'`, NOT with `-helper-text`, that only exists when helper text shows). Scope `htmlwindowname='mf_*'`.

**Evidence/state (2026-10-27):** Studio runs against Production queue items (the Studio robot is connected to Production, folder 46023) took the 4 requeued cases: 3 ended Successful (real employees created in Beam; no Beam test env), 1 Failed BusinessException. Employment-type expression and the Filter-status reorder were compiled with uipcli but not run end to end. PR build #15257: check_version + check_dependency pass, deploy.ps1 broken-by-condition (expected, runs after merge; analyzer only runs there). Fresh-eyes bot threads: Filter status thread replied (fe-ack) but needs a manual "Resolve conversation" click (auto mode blocks resolve_thread). Packages 1.6.7, 1.6.8, 1.6.9, 1.6.10 all uploaded to Staging via `uip or packages upload` (only 1.6.10 is right; no Process rebind). Jira comment 5106937 posted (plain English), ticket still In Progress, sheet row not found in tracking spreadsheet.

**Status (2026-10-27 tarde):** PR #3591 MERGEADA (11:23 UTC), Buildkite build 15258 passou (analyzer ok), 1.6.10 no feed, Process Prod (7C8C1D24-...) REBINDADO para 1.6.10 (Latest=true) com aprovação explícita do Dio. Requeue feito para os 3 InProgress sem outro registro (BVFgoIAH, BT83OIAT, BVkKfIAL; novos ids 2806038617/700/774); os outros 4 InProgress não foram recolocados: BouEr, BpkTO, BvUH7 já Successful em 27/10 00:1x, BVfGB já recolocado e falhou BusinessException. Branch ainda checada no repo principal; FloridaBlue WIP no stash@{0}.

**Closed:** ticket encerrado pelo Dio em 2026-10-27. Nada em aberto; a rodada de 06:00 com 1.6.10 não foi verificada por mim.

**Why / How to apply:** when a Beam step fails with "Target or anchors attributes has changed" or a combobox selector is generic, diff the saved page HTML (Desktop save) against the selector rather than guessing; every dropdown on this form needs the same NSelectItem treatment. Studio debug consumes real Production queue items and leaves them InProgress; check queue state after every debug session ([[feedback_studio_robot_connection_can_diverge_from_uip_cli_tenant]]). PR style: [[feedback_pr_no_claude_signature_no_tx_table]].
