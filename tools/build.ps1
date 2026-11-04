param([switch]$UseWorkspaceProfile)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $PSScriptRoot 'godot\Godot_v4.5.1-stable_win64_console.exe'
Set-Location -LiteralPath $projectRoot
if ($UseWorkspaceProfile) { $env:APPDATA = Join-Path $PSScriptRoot 'profile' }
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'templates\windows_release_x86_64.exe'))) {
    throw 'Missing templates. Run python tools/fetch_templates.py or configure your installed Godot Windows templates in Export.'
}
& $enginePath --headless --path $projectRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $enginePath --headless --path $projectRoot --script tools/export_licenses.gd
& $enginePath --headless --path $projectRoot --export-release 'Windows Desktop' 'build/DUSTLINE.exe'
if ($LASTEXITCODE -ne 0) { throw 'Godot export failed.' }
Copy-Item -LiteralPath 'README.md','LICENSE','docs\GODOT-LICENSE.txt','docs\THIRD_PARTY_NOTICES.json' -Destination 'build' -Force
New-Item -ItemType Directory -Force -Path 'build\docs' | Out-Null
Get-ChildItem -LiteralPath 'docs' -File | Copy-Item -Destination 'build\docs' -Force
Compress-Archive -LiteralPath 'build\DUSTLINE.exe','build\README.md','build\LICENSE','build\GODOT-LICENSE.txt','build\THIRD_PARTY_NOTICES.json','build\docs' -DestinationPath 'build\DUSTLINE-Windows-x64.zip' -Force
Get-FileHash -LiteralPath 'build\DUSTLINE.exe' -Algorithm SHA256
