# Restores Claude's memory from the hub.
# Usage: .\restore-memory.ps1 -ProjectPath "C:\Projects\biztech-uipath-rpa"
param([Parameter(Mandatory)][string]$ProjectPath)
$hub = Split-Path (Split-Path $PSScriptRoot)
# Claude names the project folder by replacing : \ / with -
$key = ($ProjectPath -replace '[:\\/]', '-')
$dest = Join-Path $env:USERPROFILE ".claude\projects\$key\memory"
New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($d in '04-process-history','05-session-history','06-learnings') {
    Copy-Item (Join-Path $hub "$d\*.md") $dest -Force
}
Write-Host "Memory restored to $dest ($((Get-ChildItem $dest -File).Count) files)"
