param(
  [Parameter(Mandatory=$true)]
  [string]$Path,
  [int]$GachaFrames = 480,
  [string]$UkExe = "uk"
)

if (-not (Test-Path $Path)) {
  Write-Error "File not found: $Path"
  exit 1
}
if (-not (Get-Command $UkExe -ErrorAction SilentlyContinue)) {
  Write-Error "uk executable not found in PATH or path: $UkExe"
  exit 1
}

$text = Get-Content -Raw -Encoding UTF8 $Path
$parts = $text -split "__END__", 2
$code = $parts[0]
$data = if ($parts.Length -gt 1) { $parts[1] } else { "" }

# 1. Forbidden API & mrubyedge unimplemented method scan
$patterns = @(
  "\b(map|mget|mset|mdel|mclear|sfx|music|play|tone)\b",
  "\.(sample|shuffle|reverse|delete|key\?|include\?|fetch|dig|gsub|sub|even\?|odd\?|upto|downto)\b",
  "\b(sleep|Time\.now)\b",
  "@(MAP|SFX|MUSIC)\b"
)
$forbiddenHits = 0
foreach ($p in $patterns) {
  $matches = [regex]::Matches($text, $p)
  foreach ($m in $matches) {
    # Ignore comment lines in code section for common English words like "play"
    Write-Host "[WARN/HIT] pattern=$p value=$($m.Value)"
    $forbiddenHits++
  }
}

# Re-check strictly excluding comment-only lines for non-directive words
$strictHits = 0
$codeLines = $code -split "`r?`n"
$lineNo = 0
foreach ($ln in $codeLines) {
  $lineNo++
  $trimmed = $ln.Trim()
  if ($trimmed.StartsWith("#")) { continue }
  # Strip inline comment (outside strings, simple heuristic)
  $noComment = ($ln -split "#", 2)[0]
  foreach ($p in $patterns) {
    $ms = [regex]::Matches($noComment, $p)
    foreach ($m in $ms) {
      # Allow string literals containing "play" (e.g. "PLAY AGAIN")
      if ($m.Value -eq "play" -and $noComment -match '"[^"]*\bplay\b[^"]*"') { continue }
      Write-Host "[FORBIDDEN] line ${lineNo}: $($m.Value) in $trimmed"
      $strictHits++
    }
  }
}
if ($data -match "@(MAP|SFX|MUSIC)\b") {
  Write-Host "[FORBIDDEN] Found @MAP/@SFX/@MUSIC directive in __END__"
  $strictHits++
}

# 2. Sprite dimension scan
$spriteErrors = 0
if ($data -ne "") {
  $lines = $data -split "`r?`n"
  $curName = $null; $w = 0; $h = 0; $frameIdx = 0; $rowCount = 0
  function Finish-Frame {
    if ($script:curName -and $script:rowCount -ne $script:h) {
      Write-Host "[SPRITE ERROR] $($script:curName) frame $($script:frameIdx): rows=$($script:rowCount) expected=$($script:h)"
      $script:spriteErrors++
    }
  }
  foreach ($raw in $lines) {
    $l = $raw.Trim()
    if ($l -match "^@SPRITE\s+(\S+)\s+(\d+)x(\d+)") {
      Finish-Frame
      $curName = $Matches[1]; $w = [int]$Matches[2]; $h = [int]$Matches[3]
      $frameIdx = 0; $rowCount = 0
    } elseif ($l -eq "---" -and $curName) {
      Finish-Frame
      $frameIdx++; $rowCount = 0
    } elseif ($l.StartsWith("@") -or $l.StartsWith("#") -or $l -eq "") {
      if ($l.StartsWith("@") -and $curName) { Finish-Frame; $curName = $null }
    } elseif ($curName) {
      $rowCount++
      if ($l.Length -ne $w) {
        Write-Host "[SPRITE ERROR] $curName frame $frameIdx row $rowCount len=$($l.Length) expected=$w"
        $spriteErrors++
      }
    }
  }
  Finish-Frame
}

Write-Host "Scan summary: strictForbidden=$strictHits spriteErrors=$spriteErrors"
if ($strictHits -gt 0 -or $spriteErrors -gt 0) {
  exit 1
}

# 3. uk check (60F)
& $UkExe check $Path
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 4. uk check -g (gacha mode)
& $UkExe check $Path -g --frames $GachaFrames
exit $LASTEXITCODE
