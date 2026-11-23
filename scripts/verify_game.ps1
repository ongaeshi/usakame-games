param(
  [Parameter(Mandatory=$true)]
  [string]$Path,
  [int]$GachaFrames = 480,
  [string]$UkExe = "uk"
)

$pyScript = Join-Path $PSScriptRoot "verify_game.py"
if (-not (Test-Path $pyScript)) {
  Write-Error "verify_game.py not found: $pyScript"
  exit 1
}

& python $pyScript $Path --gacha-frames $GachaFrames --uk $UkExe
exit $LASTEXITCODE
