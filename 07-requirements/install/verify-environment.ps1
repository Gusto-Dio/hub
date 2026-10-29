# Checks everything listed in inventory.md and prints PASS / WARN / FAIL per item. Read-only: installs nothing.
# Usage: powershell -NoProfile -File verify-environment.ps1 [-RepoPath C:\Projects\biztech-uipath-rpa] [-ShareLetter U]
param(
    [string]$RepoPath = 'C:\Projects\biztech-uipath-rpa',
    [string]$ShareLetter = 'U'
)
$hub = Split-Path (Split-Path $PSScriptRoot)
$script:rows = @()
function Add-Result($name, $status, $detail) { $script:rows += [pscustomobject]@{ Item = $name; Status = $status; Detail = $detail } }
function Try-Cmd($exe, $args_) { try { (& $exe @args_ 2>&1 | Out-String).Trim() } catch { $null } }

# --- core tools
$v = Try-Cmd git @('--version');  if ($v -match 'git version') { Add-Result 'git' PASS $v } else { Add-Result 'git' FAIL 'not found' }
$n = Try-Cmd git @('config','--global','user.name'); $e = Try-Cmd git @('config','--global','user.email')
if ($n -eq 'Diogenes Ribeiro' -and $e -eq 'diogenes.ribeiro@gusto.com') { Add-Result 'git identity' PASS "$n <$e>" } else { Add-Result 'git identity' FAIL "name='$n' email='$e'" }
$v = Try-Cmd node @('--version'); if ($v -match '^v\d+') { Add-Result 'node' PASS $v } else { Add-Result 'node' FAIL 'not found' }
$v = Try-Cmd dotnet @('--list-sdks'); if ($v -match '(?m)^8\.') { Add-Result 'dotnet SDK 8' PASS (($v -split "`n")[0]) } else { Add-Result 'dotnet SDK 8' FAIL "got: $v" }
$v = Try-Cmd python @('--version'); if ($v -match 'Python 3\.1[0-9]') { Add-Result 'python' PASS $v } else { Add-Result 'python' FAIL "got: $v" }
$p = Try-Cmd python @('-m','pip','list');
foreach ($pkg in 'pillow','boto3') { if ($p -match "(?im)^$pkg\s") { Add-Result "pip $pkg" PASS 'installed' } else { Add-Result "pip $pkg" FAIL 'missing (python -m pip install pillow boto3)' } }
$v = Try-Cmd claude @('--version'); if ($v -match '\d+\.\d+') { Add-Result 'claude code' PASS $v } else { Add-Result 'claude code' FAIL 'not found' }

# --- user PATH (read the registry value, not $env:Path)
$up = [Environment]::GetEnvironmentVariable('Path','User')
foreach ($frag in 'Python','\npm') { if ($up -match [regex]::Escape($frag)) { Add-Result "user PATH has $frag" PASS '' } else { Add-Result "user PATH has $frag" WARN 'not in user PATH' } }

# --- uip
$v = Try-Cmd uip @('--version'); if ($v -match '\d+\.\d+') { Add-Result 'uip cli' PASS $v } else { Add-Result 'uip cli' FAIL 'not found (npm i -g @uipath/cli)' }
$s = Try-Cmd uip @('login','status')
if ($s -match '"Status":\s*"Logged in"') {
    $org = if ($s -match '"Organization":\s*"([^"]+)"') { $Matches[1] }; $ten = if ($s -match '"Tenant":\s*"([^"]+)"') { $Matches[1] }
    Add-Result 'uip login' PASS "org=$org tenant=$ten"
    if ($org -ne 'gustoinc') { Add-Result 'uip org' FAIL "expected gustoinc, got $org" }
    if ($ten -ne 'Staging')  { Add-Result 'uip default tenant' WARN "is $ten; the working default is Staging" }
} else { Add-Result 'uip login' FAIL 'not logged in (uip login)' }

# --- repos
if (Test-Path "$RepoPath\.git") { Add-Result 'repo clone' PASS "$RepoPath on $(git -C $RepoPath branch --show-current)" } else { Add-Result 'repo clone' FAIL "$RepoPath missing" }
if (Test-Path "$hub\.git") { Add-Result 'hub clone' PASS $hub } else { Add-Result 'hub clone' FAIL "$hub is not a git clone" }

# --- share
if (Test-Path "${ShareLetter}:\") { Add-Result "share ${ShareLetter}:" PASS (Get-PSDrive $ShareLetter -ErrorAction SilentlyContinue).DisplayRoot } else { Add-Result "share ${ShareLetter}:" FAIL 'not mapped (see network-drives.md; may need IT access)' }

# --- apps
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe","${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ }
if ($chrome) { Add-Result 'chrome' PASS 'installed' } else { Add-Result 'chrome' FAIL 'not installed' }
$excel = @("$env:ProgramFiles\Microsoft Office\root\Office16\EXCEL.EXE","${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\EXCEL.EXE") | Where-Object { Test-Path $_ }
if ($excel) { Add-Result 'excel' PASS 'installed' } else { Add-Result 'excel' WARN 'not found (needed by Excel activities)' }
$studio = @("$env:ProgramFiles\UiPath\Studio\UiPath.Studio.exe","$env:LOCALAPPDATA\Programs\UiPath\Studio\UiPath.Studio.exe") | Where-Object { Test-Path $_ }
if ($studio) { Add-Result 'uipath studio' PASS 'installed' } else { Add-Result 'uipath studio' WARN 'not found in the usual paths' }
$ext = Get-ChildItem "$env:LOCALAPPDATA\Google\Chrome\User Data\*\Extensions" -Directory -ErrorAction SilentlyContinue
Add-Result 'chrome UiPath extension' WARN 'cannot be checked by script: open chrome://extensions and confirm it is installed as Current User'

# --- claude configuration
$cl = "$env:USERPROFILE\.claude"
if (Test-Path "$cl\CLAUDE.md") {
    $same = (Get-FileHash "$cl\CLAUDE.md").Hash -eq (Get-FileHash "$hub\CLAUDE.md").Hash
    if ($same) { Add-Result '~/.claude/CLAUDE.md' PASS 'identical to hub' } else { Add-Result '~/.claude/CLAUDE.md' WARN 'differs from hub CLAUDE.md (copy it again after a pull)' }
} else { Add-Result '~/.claude/CLAUDE.md' FAIL 'missing' }
if (Test-Path "$cl\settings.json") {
    try {
        $st = Get-Content "$cl\settings.json" -Raw | ConvertFrom-Json
        if ($st.enabledPlugins.'uipath@uipath-marketplace') { Add-Result 'plugin uipath@uipath-marketplace' PASS 'enabled' } else { Add-Result 'plugin uipath@uipath-marketplace' FAIL 'not enabled' }
        $hooks = ($st.hooks | ConvertTo-Json -Depth 10 -Compress) 2>$null
        if ($hooks -match 'uipath-edit-guard' -and $hooks -match 'Mode Mark' -and $hooks -match 'Mode Guard') { Add-Result 'hook uipath-edit-guard' PASS 'Mark + Guard configured' } else { Add-Result 'hook uipath-edit-guard' FAIL 'not configured (03-tools/hooks.md)' }
        if ($hooks -match [regex]::Escape('uipath-edit-guard.ps1')) {
            $path = [regex]::Match($hooks, '-File ([^"]+?uipath-edit-guard\.ps1)').Groups[1].Value -replace '\\\\','\'
            if ($path -and -not (Test-Path $path)) { Add-Result 'hook script path' FAIL "$path does not exist (fix the path in settings.json)" }
        }
    } catch { Add-Result 'settings.json' FAIL "unreadable: $_" }
} else { Add-Result 'settings.json' FAIL 'missing' }
foreach ($c in 'analyze','morning','followup','benops-sync','benops-triage-agent','benops-ticket-investigation','uipath-test-cases-from-ticket','benops-rpa-setup') {
    if (-not (Test-Path "$cl\commands\$c.md")) { Add-Result "command /$c" FAIL 'missing in ~/.claude/commands' }
}
$key = ($RepoPath -replace '[:\\/]', '-')
$mem = "$cl\projects\$key\memory"
if (Test-Path $mem) { $cnt = (Get-ChildItem $mem -File -Filter *.md).Count; if ($cnt -ge 100) { Add-Result 'memory restored' PASS "$cnt files in $mem" } else { Add-Result 'memory restored' WARN "only $cnt files (run restore-memory.ps1)" } } else { Add-Result 'memory restored' FAIL "$mem missing (run restore-memory.ps1)" }
Add-Result 'MCP connectors' WARN 'cannot be checked by script: run /mcp inside Claude and authenticate GitHub, Jira, Slack, Notion, Buildkite, Gmail, Sheets'

$script:rows | Format-Table -AutoSize -Wrap
$f = ($script:rows | Where-Object Status -eq 'FAIL').Count; $w = ($script:rows | Where-Object Status -eq 'WARN').Count
Write-Host "FAIL: $f   WARN: $w   PASS: $(($script:rows | Where-Object Status -eq 'PASS').Count)"
exit ([int]($f -gt 0))
