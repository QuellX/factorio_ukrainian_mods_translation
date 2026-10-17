param([Parameter(Mandatory)][string]$List)
$ErrorActionPreference = 'Stop'
# Remove keys from pack files. $List: text file, one "<file.cfg>|<section>/<key>" per line (# = comment).
# Used to drop translations that were made for a mod that is no longer installed but whose keys now
# override another installed mod or the base game (see stale.ps1 -Detail).
$packDir = "$(Split-Path $PSScriptRoot -Parent)\ukrainian-mods-translation\locale\uk"
$byFile = @{}
foreach ($l in [IO.File]::ReadAllLines($List, [Text.Encoding]::UTF8)) {
  $t = $l.Trim(); if ($t -eq '' -or $t[0] -eq '#') { continue }
  $f, $k = $t -split '\|', 2
  if (-not $byFile.ContainsKey($f)) { $byFile[$f] = @{} }
  $byFile[$f][$k.Trim()] = 1
}
$enc = New-Object Text.UTF8Encoding $false
foreach ($f in $byFile.Keys) {
  $path = Join-Path $packDir $f
  $out = New-Object Collections.Generic.List[string]; $sec = ''; $n = 0
  foreach ($l in [IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8)) {
    $t = $l.Trim()
    if ($t -match '^\[(.+)\]$') { $sec = $matches[1] }
    else { $i = $l.IndexOf('='); if ($i -gt 0 -and -not $t.StartsWith(';') -and $byFile[$f].ContainsKey("$sec/" + $l.Substring(0, $i).Trim())) { $n++; continue } }
    $out.Add($l)
  }
  [IO.File]::WriteAllLines($path, $out, $enc)
  "$f : removed $n of $($byFile[$f].Count)"
}
