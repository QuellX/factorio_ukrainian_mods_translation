param([switch]$Fix)
$ErrorActionPreference = 'Stop'
# Find __ITEM__x__ / __ENTITY__x__ / ... references in the effective uk text (mods' uk, overridden by our pack)
# whose target name does not exist in any en locale (game + mods) -> Factorio shows "Unknown key: item-name.x".
# Typical cause: a mod renamed its prototypes (Krastorio2 2.x added "kr-") but its uk locale still uses old names.
# -Fix writes locale\uk\ref-fixes.cfg: stale refs replaced by the matching ref from the English string of the same key.
$repo = Split-Path $PSScriptRoot -Parent; $modsDir = "$repo\mods"; $packDir = "$repo\ukrainian-mods-translation\locale\uk"
$game = 'E:\games\steam\steamapps\common\Factorio\data'
function ParseDir($dir, $h) {
  foreach ($f in Get-ChildItem $dir -Filter *.cfg -ErrorAction SilentlyContinue) {
    $sec = ''
    foreach ($line in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      $t = $line.TrimStart([char]0xFEFF).Trim()
      if ($t -eq '' -or $t.StartsWith(';') -or $t.StartsWith('#')) { continue }
      if ($t -match '^\[(.+)\]$') { $sec = $matches[1].Trim(); continue }
      $i = $line.IndexOf('='); if ($i -lt 1) { continue }
      $h["$sec`t" + $line.Substring(0, $i).TrimStart([char]0xFEFF).Trim()] = $line.Substring($i + 1)
    }
  }
}
# names defined anywhere in en
$en = @{}; $enByMod = @{}
foreach ($p in 'core','base','space-age','quality','elevated-rails','recycler') { ParseDir "$game\$p\locale\en" $en }
$mods = @(Get-ChildItem $modsDir -Directory | Where-Object { $_.Name -notlike 'ukrainian-mods-translation*' })
foreach ($m in $mods) { $h = @{}; ParseDir "$($m.FullName)\locale\en" $h; $enByMod[$m.Name] = $h; foreach ($k in $h.Keys) { $en[$k] = $h[$k] } }
$names = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($k in $en.Keys) { $s, $n = $k -split "`t", 2; if ($s -like '*-name') { [void]$names.Add("$s|$n") } }
$accept = @{
  ITEM = 'item-name','entity-name','equipment-name','tile-name','fluid-name'
  ENTITY = 'entity-name','item-name'
  FLUID = 'fluid-name'
  TECHNOLOGY = 'technology-name'
  RECIPE = 'recipe-name','item-name','fluid-name','entity-name'
  TILE = 'tile-name','item-name'
  EQUIPMENT = 'equipment-name','item-name'
  SPACE_LOCATION = 'space-location-name'
  ITEM_GROUP = 'item-group-name'
  VIRTUAL_SIGNAL = 'virtual-signal-name'
}
function Exists($type, $name) { foreach ($s in $accept[$type]) { if ($names.Contains("$s|$name")) { return $true } }; return $false }
$rx = [regex]'__(ITEM|ENTITY|FLUID|TECHNOLOGY|RECIPE|TILE|EQUIPMENT|SPACE_LOCATION|ITEM_GROUP|VIRTUAL_SIGNAL)__([A-Za-z0-9_\-]+?)__'

$pack = @{}; ParseDir $packDir $pack
$fixFile = Join-Path $packDir 'ref-fixes.cfg'
$packNoFix = @{}; ParseDir $packDir $packNoFix
if (Test-Path $fixFile) { $tmp = @{}; ParseDir $packDir $tmp; $rf = @{}; $sec = ''
  foreach ($line in [IO.File]::ReadAllLines($fixFile, [Text.Encoding]::UTF8)) { if ($line -match '^\[(.+)\]$') { $sec = $matches[1] } elseif ($line.IndexOf('=') -gt 0) { $rf["$sec`t" + $line.Substring(0, $line.IndexOf('='))] = 1 } }
  foreach ($k in $rf.Keys) { $packNoFix.Remove($k) } }

$fixes = [ordered]@{}; $manual = 0; $found = 0
foreach ($m in $mods) {
  $uk = @{}; ParseDir "$($m.FullName)\locale\uk" $uk
  foreach ($k in $enByMod[$m.Name].Keys) {
    if ($packNoFix.ContainsKey($k)) { $v = $packNoFix[$k]; $src = 'PACK' } elseif ($uk.ContainsKey($k)) { $v = $uk[$k]; $src = 'mod' } else { continue }
    $enV = $enByMod[$m.Name][$k]
    # a ref that the English string itself also uses is the mod's own upstream problem (or resolved by code) - skip
    $bad = @($rx.Matches($v) | Where-Object { -not (Exists $_.Groups[1].Value $_.Groups[2].Value) -and -not $enV.Contains($_.Value) })
    if ($bad.Count -eq 0) { continue }
    $enRefs = @($rx.Matches($enByMod[$m.Name][$k]))
    $new = $v; $ok = $true
    foreach ($b in $bad) {
      $found++
      $t = $b.Groups[1].Value; $n = $b.Groups[2].Value
      $cand = @($enRefs | Where-Object { $_.Groups[1].Value -eq $t -and ($_.Groups[2].Value -eq "kr-$n" -or $_.Groups[2].Value.EndsWith("-$n")) -and (Exists $t $_.Groups[2].Value) } | ForEach-Object { $_.Value } | Select-Object -Unique)
      if ($cand.Count -eq 0) { $cand = @($enRefs | Where-Object { (Exists $_.Groups[1].Value $_.Groups[2].Value) -and $_.Groups[2].Value.EndsWith($n) } | ForEach-Object { $_.Value } | Select-Object -Unique) }
      if ($cand.Count -eq 1) { $new = $new.Replace($b.Value, $cand[0]); "STALE $($m.Name) :: $($k.Replace("`t",' / ')) [$src] $($b.Value) -> $($cand[0])" }
      else { $ok = $false; $manual++; "MANUAL $($m.Name) :: $($k.Replace("`t",' / ')) [$src] $($b.Value)  (en: $($enByMod[$m.Name][$k]))" }
    }
    if ($ok -and $src -eq 'mod') { $s, $key = $k -split "`t", 2; if (-not $fixes.Contains($s)) { $fixes[$s] = [ordered]@{} }; $fixes[$s][$key] = $new }
    elseif ($ok) { $manual++; "  ^ key is in our pack: fix it there" }
  }
}
"--- stale refs: $found, auto-fixable keys: $(($fixes.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum), manual: $manual"
if ($Fix) {
  $sb = New-Object Text.StringBuilder
  [void]$sb.AppendLine('; Generated by tools/refs.ps1 -Fix: mods'' uk strings referencing renamed prototypes (e.g. Krastorio2 "kr-" prefix).')
  foreach ($s in $fixes.Keys) { [void]$sb.AppendLine(); [void]$sb.AppendLine("[$s]"); foreach ($key in $fixes[$s].Keys) { [void]$sb.AppendLine("$key=$($fixes[$s][$key])") } }
  if ($fixes.Count) { [IO.File]::WriteAllText($fixFile, $sb.ToString(), (New-Object Text.UTF8Encoding $false)); "written $fixFile" }
  elseif (Test-Path $fixFile) { [IO.File]::Delete($fixFile); "nothing to fix; removed $fixFile" }
}
