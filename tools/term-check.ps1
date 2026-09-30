<#
Flags Ukrainian strings that don't follow tools/term-rules.txt.
  term-check.ps1 -Dir <folder with *.cfg written by diff-global.ps1 "existing" (;EN comment + key=uk)>
  term-check.ps1 -Pack        check our own pack against the English of every mod
Output: one block per flagged string (mod, key, missing term, EN, UK) and a per-rule summary.
#>
param([string]$Dir, [switch]$Pack)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$rules = @()
foreach ($l in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot 'term-rules.txt'), [Text.Encoding]::UTF8)) {
  if ($l.Trim() -eq '' -or $l.TrimStart().StartsWith('#')) { continue }
  $p = $l -split '\s=>\s', 2
  $rules += [pscustomobject]@{ En = [regex]::new($p[0].Trim(), 'IgnoreCase'); Uk = [regex]::new($p[1].Trim(), 'IgnoreCase'); Name = $p[0].Trim() }
}
function Strip($s) { [regex]::Replace($s, '__[A-Z_]+__[^_\s]*?__|__\d+__|\[[^\]]*\]', ' ') }

$pairs = @()   # mod, key, en, uk
if ($Dir) {
  foreach ($f in Get-ChildItem $Dir -Filter *.cfg) {
    $sec = ''; $en = $null
    foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      if ($l -match '^\[(.+)\]$') { $sec = $matches[1]; continue }
      if ($l.StartsWith(';EN ')) { $en = $l.Substring(4); continue }
      $i = $l.IndexOf('='); if ($i -lt 1 -or $null -eq $en) { continue }
      $pairs += [pscustomobject]@{ Mod = $f.BaseName; Key = "$sec/" + $l.Substring(0, $i); En = $en; Uk = $l.Substring($i + 1) }; $en = $null
    }
  }
}
if ($Pack) {
  $en = @{}
  foreach ($d in Get-ChildItem (Join-Path $repo 'mods') -Directory) {
    $ed = Join-Path $d.FullName 'locale\en'; if (-not (Test-Path $ed)) { continue }
    foreach ($f in Get-ChildItem $ed -Filter *.cfg) { $sec = ''; foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) { $t = $l.Trim(); if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; continue }; $i = $l.IndexOf('='); if ($i -gt 0) { $en["$sec/" + $l.Substring(0, $i).Trim()] = $l.Substring($i + 1) } } }
  }
  foreach ($f in Get-ChildItem (Join-Path $repo 'ukrainian-mods-translation\locale\uk') -Filter *.cfg) {
    $sec = ''; foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) { if ($l -match '^\[(.+)\]$') { $sec = $matches[1]; continue }; $i = $l.IndexOf('='); if ($i -gt 0) { $k = "$sec/" + $l.Substring(0, $i).Trim(); if ($en.ContainsKey($k)) { $pairs += [pscustomobject]@{ Mod = $f.BaseName; Key = $k; En = $en[$k]; Uk = $l.Substring($i + 1) } } } }
  }
}
$count = @{}; $n = 0
foreach ($p in $pairs) {
  $e = Strip $p.En; $u = Strip $p.Uk
  $miss = @(); foreach ($r in $rules) { if ($r.En.IsMatch($e) -and -not $r.Uk.IsMatch($u)) { $miss += $r.Name; $count[$r.Name] = 1 + $count[$r.Name] } }
  if ($miss) { $n++; "#$n $($p.Mod) | $($p.Key) | missing: $($miss -join ', ')`n  EN: $($p.En)`n  UK: $($p.Uk)" }
}
"--- flagged $n of $($pairs.Count)"
$count.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { "{0,5}  {1}" -f $_.Value, $_.Key }
