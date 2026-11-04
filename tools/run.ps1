param([switch]$Editor, [switch]$Tests)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $PSScriptRoot 'godot\Godot_v4.5.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw 'Godot portable missing. Install Godot 4.5.1 or use build/DUSTLINE.exe.' }
Set-Location -LiteralPath $projectRoot
if ($Tests) {
    $env:APPDATA = Join-Path $PSScriptRoot 'profile'
    & $enginePath --headless --path $projectRoot --script tests/test_runner.gd
} elseif ($Editor) {
    & $enginePath --editor --path $projectRoot
} else {
    & $enginePath --path $projectRoot
}
exit $LASTEXITCODE
