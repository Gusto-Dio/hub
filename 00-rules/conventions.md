# Conventions

## Naming
- Arguments: PascalCase with direction prefix: `in_Gender`, `out_Result`, `io_EmployeeData`.
- Variables: camelCase: `genderValue`, `isDropdownOpen`.
- Workflow files: PascalCase: `EnterEmployeeInformation.xaml`.
- Process folders: `Processes/Benefits/CarrierAutomations/<MemberSubmission|GroupSubmission|Reconciliation|...>/<Carrier>/<Process>/`. Libraries: `Libraries/Gusto_*`.

## Selectors
- Prefer stable attributes (`aria-role`, `data-testid`, ids) over `idx` or absolute `parentid`. Parameterize dynamic parts: `aaname='{in_EmployeeName}'`.
- Validate the selector against the live page before committing. To diagnose a missing element, save the page and grep for its text or `data-testid` (`feedback_dom_grep_diagnose_missing_element`). Anthem iframes: save by screenshot or DOM, not "save HTML" (`feedback_anthem_iframe_html_save_unreliable`).
- Angular tables: FuzzySelector is unreliable; use a Strict Selector (`tableRow`/`tableCol`/`colName`) with `InteractionMode="DebuggerApi"` (`feedback_angular_table_colname_rowname_unreliable`).
- `parentid='capture'` is not a real container; it broke several UHC selectors (BT-75581).
- `UiElementExists` must use the same full selector chain as the Click it guards (`feedback_uielementexists_selector_must_match_click`).
- `ScopeIdentifier` copied from another file makes a Check find the element while the Click fails (`feedback_scope_identifier_mismatch`).

## Activities
- `TypeInto` with `InteractionMode=Simulate` does not fire Angular events; reactive tables never re-filter. Use a mode that raises real events (`feedback_angular_typeinto_simulate_mode_no_events`, `project_bt76044_uhc_census_ancillary_columns`).
- `uix:NCheck` delays (`DelayBefore`/`DelayAfter`) are in SECONDS (`reference_ncheck_delay_units`).
- GSuite `ReadRange` is not cancel-safe: do not wrap it in Pick/TimeoutMS (`feedback_gsuite_readrange_not_cancel_safe`). Sheet tab names can have a leading space (`feedback_gsheets_sheet_name_leading_space`).
- Re-saving a XAML in Studio creates diff noise: isolate the real change by IdRef, revert and reapply (`feedback_studio_resave_diff_noise`).
- Studio does not support the `rpa-tool` on this machine; use a breakpoint on the whole file or manual debug (`feedback_studio_rpa_tool_unsupported`).
- Assembly load errors: diff `project.json` against HEAD first; it is almost always an uncommitted bump, not cache corruption (`feedback_assembly_load_error_check_worktree_diff`, `feedback_connectionclient_assembly_load_needs_explicit_pin`).

## Exceptions
- `BusinessRuleException` for expected business outcomes (item cannot proceed, no retry); system exceptions for faults. See `production-and-uip.md` for why the gate must not be widened.
