# Orchestrator Log Query Guide

## Authentication
Auth token stored at `~/.uipath/.auth` after `uip login`. If expired, run `uip login` first.

## Query Sequence

```powershell
# 1. List recent failed jobs for the process
# GET .../odata/Jobs?$filter=ReleaseName eq '<ProcessName>' and State eq 'Faulted'&$orderby=CreationTime desc&$top=5

# 2. Get the job GUID (NOT the integer ID)
# GET .../odata/Jobs(<integer-id>)  →  extract field "Key" (GUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)

# 3. Query robot logs using the GUID
# GET .../odata/RobotLogs?$filter=JobKey eq guid'<GUID>'&$orderby=TimeStamp asc
```

**Critical:** Always use the GUID `Key` field, not the integer job ID. The OData filter `JobKey eq guid'...'` requires the GUID format — using the integer ID causes a type mismatch error.

Read the full log sequence, not just the first error. A second failure is often downstream of the first.

## BenOps Orchestrator Tenants

| Env | Folder | Folder ID |
|---|---|---|
| Production | Benefits | 46023 |
| Production | CarrierAutomation | 944168 |
| Staging | Benefits | 48382 |
| Staging | CarrierAutomation | 946022 |

## Error Pattern Reference

| Error pattern | Root cause area |
|---|---|
| `Could not find file '...\SomeWorkflow.xaml'` | InvokeWorkflowFile referencing a non-existent file |
| `Element not found` / selector timeout | Selector issue, popup blocking UI, or page not fully loaded |
| `Object reference not set` | Variable not initialized, or a workflow returned without setting its output argument |
| `An ExceptionActivity was thrown` | Explicit Business Rule Exception inside the workflow |
| `The process cannot access the file` | File lock — another process or Studio has the file open |
| `Login failed` / `Authentication error` | Carrier portal credential change or SSO session expired |
