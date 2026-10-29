# Session protocol

The hub is the single source of continuity between sessions and machines. Hub clone: `C:\Projects\hub` (VM), `U:\hub` (old VDI).

## Where things live (no separate "memory" folder on purpose)
Claude's memory is not duplicated into a folder of its own. It is already split by type and `03-tools/scripts/restore-memory.ps1` puts it back into Claude's memory directory:
- `05-session-history/MEMORY.md`: the index (one line per memory). Read first.
- `05-session-history/work_state.md`: the CURRENT state: open PRs, in progress, pending. Overwritten, not appended.
- `05-session-history/sessions/`: one short note per session, in chronological order (see below).
- `04-process-history/project_*.md`: one file per ticket or process.
- `06-learnings/feedback_*.md`, `reference_*.md`: lessons and pointers.

## At the start of a session (before answering anything)
1. Read `work_state.md`.
2. Read the latest 3 files in `05-session-history/sessions/` (sorted by file name = chronological). Surface every item marked PENDING or BLOCKED to Dio in one short list.
3. Read `MEMORY.md`; open only the memories the task needs.
4. Read the rules selected in `00-rules/README.md`.
5. Run `07-requirements/install/verify-environment.ps1` and handle the result as `CLAUDE.md` describes (report FAIL and WARN, ask before installing, never reinstall what passes). Known WARNs that need no action: Chrome extension and MCP connectors (not checkable by script).
6. If the hub clone is behind `origin/main`, say so (`git -C <hub> fetch` then compare); a stale hub gives stale rules. Pull needs no approval; push does.

## During the session
- Save a memory when Dio corrects you, confirms a non-obvious approach, or a ticket reaches a state worth keeping (PR opened, deployed, closed, blocked). One fact per file, frontmatter with `name`, `description`, `metadata.type`.
- Use the real session id in memory frontmatter (`originSessionId`). The id is in the scratchpad path of the session (the folder name between the project folder and `scratchpad`).

## At the end of a session (or when Dio says it is a good stopping point)
1. Update `work_state.md` (current truth only; delete finished items, keep a one-line pointer to the project file).
2. Write the session note `05-session-history/sessions/YYYY-MM-DD_HHMM_<first 8 of session id>.md`:
   ```
   ---
   session_id: <full id>
   started: <ISO date and time, machine local>
   machine: VM | VDI
   tickets: [BT-XXXXX, ...]
   ---
   What was done (3 to 8 lines, plain).
   Decisions taken and why.
   PENDING: <what is not done and who owns it>
   Next step: <the first thing to do next session>
   ```
3. Sync memory files back into the hub folders (`project_*` to 04, `MEMORY.md` and `work_state.md` to 05, everything else to 06), scan for secrets and PII, commit. The push needs Dio's explicit approval and goes only to the private `Gusto-Dio/hub` repo.

## Why a session id, and why the file name carries a timestamp
- Order comes from the `YYYY-MM-DD_HHMM` prefix, never from the id (ids are random, not sortable).
- The id is for traceability: it matches `originSessionId` in the memories written in that session, and the transcript on the same machine (`~/.claude/projects/<project>/<id>.jsonl`, usable with `claude --resume`). Transcripts do NOT travel in the hub, so on another machine the id only links notes and memories to each other.
- Never store transcripts or logs in the hub (PII risk).
