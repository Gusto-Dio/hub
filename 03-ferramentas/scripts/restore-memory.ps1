# Restaura a memória do Claude a partir do hub.
# Uso: .\restore-memory.ps1 -ProjectPath "U:\Projects\biztech-uipath-rpa"
param([Parameter(Mandatory)][string]$ProjectPath)
$hub = Split-Path (Split-Path $PSScriptRoot)
# Claude nomeia a pasta do projeto trocando : \ / por -
$key = ($ProjectPath -replace '[:\/]', '-')
$dest = Join-Path $env:USERPROFILE ".claude\projects\$key\memory"
New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($d in '04-historicos-processo','05-historicos-sessao','06-aprendizados') {
    Copy-Item (Join-Path $hub "$d\*.md") $dest -Force
}
Write-Host "Memória restaurada em $dest ($((Get-ChildItem $dest -File).Count) arquivos)"
