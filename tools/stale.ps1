param([switch]$Detail)
$ErrorActionPreference = 'Stop'
# For every pack key: is it still used by an installed mod (or the game)? Reports per pack file
#   used   = key exists in some installed mod's en (or game en) -> still matters
#   dead   = no installed mod / game defines it -> leftover from a removed mod (harmless, dropped later)
# -Detail lists "used" keys of files whose other keys are mostly dead: these were translated for a removed mod
# and may now override a different installed mod's text (check them).
$repo = Split-Path $PSScriptRoot -Parent; $packDir = "$repo\ukrainian-mods-translation\locale\uk"
$game = 'E:\games\steam\steamapps\common\Factorio\data'
function Keys($dir, $h, $tag) {
  foreach ($f in Get-ChildItem $dir -Filter *.cfg -ErrorAction SilentlyContinue) {
    $sec = ''
    foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      $t = $l.Trim(); if ($t -eq '' -or $t[0] -eq ';' -or $t[0] -eq '#') { continue }
      if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; continue }
      $i = $l.IndexOf('='); if ($i -lt 1) { continue }
      $k = "$sec/" + $l.Substring(0, $i).Trim([char]0xFEFF, ' ')
      if (-not $h.ContainsKey($k)) { $h[$k] = $tag }
    }
  }
}
$en = @{}
foreach ($p in 'core','base','space-age','quality','elevated-rails','recycler') { Keys "$game\$p\locale\en" $en "game" }
foreach ($m in Get-ChildItem "$repo\mods" -Directory | Where-Object { $_.Name -notlike 'ukrainian-mods-translation*' }) { Keys "$($m.FullName)\locale\en" $en $m.Name }
$usedList = New-Object Collections.Generic.List[string]
$rows = foreach ($f in Get-ChildItem $packDir -Filter *.cfg) {
  $mine = @{}; $sec = ''
  foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
    $t = $l.Trim(); if ($t -eq '' -or $t[0] -eq ';') { continue }
    if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; continue }
    $i = $l.IndexOf('='); if ($i -lt 1) { continue }
    $mine["$sec/" + $l.Substring(0, $i).Trim([char]0xFEFF, ' ')] = 1
  }
  $used = @($mine.Keys | Where-Object { $en.ContainsKey($_) })
  [pscustomobject]@{ File = $f.Name; Keys = $mine.Count; Used = $used.Count; Dead = $mine.Count - $used.Count; UsedBy = (($used | ForEach-Object { $en[$_] } | Group-Object | Sort-Object Count -Descending | Select-Object -First 4 | ForEach-Object { "$($_.Name)($($_.Count))" }) -join ' ') }
  if ($Detail -and $used.Count -and $used.Count -lt ($mine.Count - $used.Count)) { foreach ($u in $used) { $usedList.Add("  USED $($f.Name) :: $u  <- $($en[$u])") } }
}
$rows | Sort-Object Dead -Descending | Format-Table -AutoSize | Out-String -Width 250
$usedList
