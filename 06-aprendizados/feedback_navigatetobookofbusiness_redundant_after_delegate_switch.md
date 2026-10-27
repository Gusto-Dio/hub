---
name: feedback_navigatetobookofbusiness_redundant_after_delegate_switch
description: Kaiser gkg:NavigateToBookOfBusiness is redundant once gkg:SwitchToDelegatedAccount runs first — both end up clicking 'Manage Members', causing a double-click
metadata:
  type: feedback
  originSessionId: fc2006b8-97b4-4993-82c5-23e7ef1bc824
  modified: 2026-09-10T20:21:38.816Z
---

In the Kaiser CA processes (`Gusto_Benefits` mega-lib, `Kaiser_CA/Generic`), `gkg:SwitchToDelegatedAccount` (added for BT-75495) already lands the browser in a state where "Manage Members" is directly clickable — confirmed by `Kaiser_CA_MemberUpdates`'s own `SearchForGroup.xaml`, which clicks "Manage Members" itself right after the delegate switch, with no extra navigation step.

`gkg:NavigateToBookOfBusiness` (used by `Kaiser_CA_Terminations` and `Kaiser_CA_NewHireEnrollment` before BT-75495) clicks "Book of Business" **then** "Manage Members" then checks a "Groups" element. Once `SwitchToDelegatedAccount` is wired in ahead of it, calling `NavigateToBookOfBusiness` afterward means "Manage Members" gets clicked twice (once via `NavigateToBookOfBusiness`, once via the process's own `SearchForGroup.xaml`), which is at best redundant and could contribute to state/timing issues.

**How to apply:** When wiring `gkg:SwitchToDelegatedAccount` into a Kaiser CA process that previously called `gkg:NavigateToBookOfBusiness` right after login, remove the `NavigateToBookOfBusiness` call entirely — mirror `Kaiser_CA_MemberUpdates`'s pattern (login → switch → let the process's own `SearchForGroup`/equivalent workflow handle the "Manage Members" click). Verified via full diff comparison that `Kaiser_CA_Terminations`'s and `Kaiser_CA_MemberUpdates`'s `SearchForGroup.xaml` are structurally identical at the relevant step (same `NApplicationCard`/`NClick` targeting `title='Manage Members - Kaiser Permanente'`, `Url='https://account.kp.org/EBSS/ebssp#/groups/subgroups/members'`).
