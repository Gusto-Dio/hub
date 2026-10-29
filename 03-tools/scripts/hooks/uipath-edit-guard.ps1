# Claude Code hook helper for the XAML edit protocol (00-rules/xaml-and-skills.md).
#   -Mode Mark  : PostToolUse on the Skill tool. Records that uipath:uipath-rpa was invoked in this session.
#   -Mode Guard : PreToolUse on Edit|Write|MultiEdit. Blocks (exit 2) edits of .xaml/.cs/project.json when
#                 the repo is on develop/main, or when uipath:uipath-rpa has not been invoked in this session.
# Hook input arrives as JSON on stdin. Exit 2 + stderr = the tool call is blocked and the message goes to Claude.
param([Parameter(Mandatory)][ValidateSet('Mark','Guard')][string]$Mode)

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
$in = $raw | ConvertFrom-Json
$sid = if ($in.session_id) { $in.session_id } else { 'unknown' }
$marker = Join-Path $env:TEMP "uipath-rpa-skill-$sid.ok"

if ($Mode -eq 'Mark') {
    if ($in.tool_input.skill -eq 'uipath:uipath-rpa') { New-Item -ItemType File -Force $marker | Out-Null }
    exit 0
}

$path = $in.tool_input.file_path
if (-not $path) { exit 0 }
if ($path -notmatch '\.(xaml|cs)$' -and $path -notmatch '(^|[\\/])project\.json$') { exit 0 }

$dir = Split-Path $path -Parent
while ($dir -and -not (Test-Path (Join-Path $dir '.git'))) { $dir = Split-Path $dir -Parent }
if ($dir) {
    $branch = (git -C $dir branch --show-current 2>$null)
    if ($branch -in 'develop','main') {
        [Console]::Error.WriteLine("Blocked: repo is on '$branch'. Create a BT-XXXXX branch off origin/develop before editing.")
        exit 2
    }
}
if (-not (Test-Path $marker)) {
    [Console]::Error.WriteLine("Blocked: invoke the skill uipath:uipath-rpa before editing .xaml/.cs/project.json in this session (00-rules/xaml-and-skills.md).")
    exit 2
}
exit 0
