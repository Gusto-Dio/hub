---
name: feedback_gmail_via_filter_breaks_after_sender_change
description: "Gmail filters matching a display-name with a 'via X' fragment silently stop firing when the sender's send path changes (e.g. after a Delegate Account credential swap) — check this before suspecting XAML/regex bugs in MFA code retrieval"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 30519834-d6b4-4b19-a59f-f9cbbdc38ee6
  modified: 2026-09-12T01:05:46.681Z
---

When a UiPath carrier-login workflow reads an MFA/access code from a shared mailbox
(`benefitsoperations@gusto.com`) via a Gmail label (`GetIMAPMailMessages` with `MailFolder="<label>"`),
that label is applied by a Gmail filter — usually matching `From`. If the filter's `From` criterion
includes a `via X` fragment (e.g. `from:("Blue Shield of California" via Carrier Operations)`), that
`via X` text is **Gmail's own annotation**, shown only when the sending path/SPF doesn't align with the
display domain. It is NOT part of the actual sender address, and it can silently disappear or change if
the carrier's send path changes — most notably after switching to a Delegate Account, which can make the
carrier send MFA email directly (no relay) instead of through whatever produced the `via` wrapper before.

**Symptom this produces, confirmed on BT-75657 (BSCA):** email arrives fast in the Inbox, but never gets
the target label → `GetIMAPMailMessages` (querying by that label/folder) finds nothing new →
`out_AccessCode` stays empty for the entire while-loop budget → `wbStatus: Successful` (loop just timed
out, no found/not-found branch) with no code ever typed. This looks exactly like a broken extraction
regex or a read/unread filter problem (the two most tempting code-level hypotheses) but is neither —
it's 100% external to the codebase, fixable in Gmail settings with zero code change.

**Why:** Discovered live on BT-75657 after a Delegate Account credential swap for BSCA. The original
filter matched `from:("Blue Shield of California" via Carrier Operations)`; post-swap, BSCA's MFA email
comes as `Blue Shield of California <WDHwebdesk2@blueshieldca.com>` with no `via` wrapper, so the filter
stopped matching. An entire investigation cycle (attempted `OnlyUnreadMessages` fix — wrong, reverted;
suspected extraction regex — also wrong) preceded finding this. See
[[project_bt75657_bsca_delegate_account_login]].

**How to apply:** Before touching `GetAccessCode.xaml` (or any similar shared MFA-retrieval workflow) for
any carrier, when the symptom is "email visibly arrives but the code never gets typed / field stays
empty": (1) confirm whether the email actually carries the target Gmail label (not just "is it in the
Inbox" — a message can sit in Inbox AND have the label, or Inbox and NOT have the label, these are
independent); (2) if the label is missing, check Gmail Filters for that address for a stale `From`
criterion containing `via X` or any other fragment tied to the old send path; (3) especially suspect this
right after any Delegate Account / credential swap for that carrier, since that's what changes the send
path. Fix in Gmail (edit the filter's `From` to the real current sender address), not in XAML. Relevant
for any of the 11 carriers sharing `Libraries/Gusto_Benefits/Generic/GetAccessCode.xaml` (BSCA, Kaiser_CA,
Anthem, UnitedHealthcare, Guardian, FloridaBlue, DeltaDental, CoveredCal, Beam) — especially ones that go
through a Delegate Account switch like Kaiser did ([[project_bt75495_kaiser_delegate_account_login]]).
