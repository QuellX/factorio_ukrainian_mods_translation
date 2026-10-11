param([string[]]$Mods)
# Copy every installed mod's own uk translation into the pack as locale\uk\own-<mod>.cfg, so the pack is
# self-contained (user rule: keep official/community uk, but copy it into our mod anyway).
# Skipped: keys already defined in a non-own pack file (our translations and terminology fixes win),
# values equal to the mod's English (untranslated), keys already copied from another mod (first one wins).
# Regenerates all own-*.cfg (or only those of -Mods). Rerun after mods update; old own-* of removed mods are kept.
$ErrorActionPreference = 'Stop'
$root = 'E:\games\mods\locale'
$myDir = "$root\ukrainian-mods-translation\locale\uk"
$utf8 = New-Object Text.UTF8Encoding($false)

function ParseFiles($files) {
  $h = [ordered]@{}
  foreach ($f in $files) {
    $sec = ''
    foreach ($l in [IO.File]::ReadAllLines($f, [Text.Encoding]::UTF8)) {
      $t = $l.TrimStart([char]0xFEFF).Trim()
      if ($t -eq '' -or $t[0] -eq ';' -or $t[0] -eq '#') { continue }
      if ($t -match '^\[(.+)\]$') { $sec = $matches[1].Trim(); continue }
      $i = $t.IndexOf('='); if ($i -lt 1) { continue }
      $h["$sec`t" + $t.Substring(0, $i).Trim()] = $t.Substring($i + 1)
    }
  }
  return $h
}
function ParseDir($dir) {
  if (-not (Test-Path $dir)) { return [ordered]@{} }
  return ParseFiles @(Get-ChildItem $dir -Filter *.cfg | Sort-Object Name | ForEach-Object { $_.FullName })
}
function SafeName($n) { return ($n -replace '[^A-Za-z0-9_.-]', '_') }

# keys defined by our own (non-copied) pack files
$taken = @{}
$ownFiles = @(Get-ChildItem $myDir -Filter *.cfg | Where-Object { $_.Name -notlike 'own-*' } | ForEach-Object { $_.FullName })
foreach ($k in (ParseFiles $ownFiles).Keys) { $taken[$k] = 1 }

$modList = @()
foreach ($d in Get-ChildItem "$root\mods" -Directory | Sort-Object Name) {
  if ($d.Name -like 'ukrainian-mods-translation*') { continue }
  $ij = Join-Path $d.FullName 'info.json'; if (-not (Test-Path $ij)) { continue }
  $name = (Get-Content $ij -Raw -Encoding UTF8 | ConvertFrom-Json).name
  if (-not (Test-Path "$($d.FullName)\locale\uk")) { continue }
  $modList += [pscustomobject]@{ Name = $name; Dir = $d.FullName }
}

# keys copied by own-* files that are NOT regenerated this run also count as taken
if ($Mods) {
  $keep = @(Get-ChildItem $myDir -Filter 'own-*.cfg' | Where-Object { $Mods -notcontains ($_.BaseName.Substring(4)) -and ($Mods | ForEach-Object { SafeName $_ }) -notcontains $_.BaseName.Substring(4) } | ForEach-Object { $_.FullName })
  foreach ($k in (ParseFiles $keep).Keys) { $taken[$k] = 1 }
  $modList = @($modList | Where-Object { $Mods -contains $_.Name })
} else {
  # full run: rewrite own-* of installed mods only (removed mods keep their file)
  $installed = @($modList | ForEach-Object { 'own-' + (SafeName $_.Name) + '.cfg' })
  $keep = @(Get-ChildItem $myDir -Filter 'own-*.cfg' | Where-Object { $installed -notcontains $_.Name } | ForEach-Object { $_.FullName })
  foreach ($k in (ParseFiles $keep).Keys) { $taken[$k] = 1 }
}

# English of every installed mod: a "uk" value equal to any mod's English for that key is untranslated
# (e.g. AAI_Language_Pack ships English names for other AAI mods) - skip it so our translation can fill it.
$allEn = @{}
foreach ($d in Get-ChildItem "$root\mods" -Directory) {
  if ($d.Name -like 'ukrainian-mods-translation*' -or -not (Test-Path "$($d.FullName)\info.json")) { continue }
  $e = ParseDir "$($d.FullName)\locale\en"
  foreach ($k in $e.Keys) { $allEn["$k`n$($e[$k])"] = 1 }
}

$total = 0
foreach ($m in $modList) {
  $uk = ParseDir "$($m.Dir)\locale\uk"; $en = ParseDir "$($m.Dir)\locale\en"
  $bySec = [ordered]@{}; $n = 0
  foreach ($k in $uk.Keys) {
    if ($taken.ContainsKey($k) -or $k -like "mod-name`t*") { continue }  # mod names stay English (english-names.ps1)
    $v = $uk[$k]; if ($v.Trim() -eq '') { continue }
    if ($en.Contains($k) -and $en[$k] -eq $v) { continue }
    if ($allEn.ContainsKey("$k`n$v")) { continue }
    $sec, $key = $k -split "`t", 2
    if (-not $bySec.Contains($sec)) { $bySec[$sec] = New-Object System.Collections.Generic.List[string] }
    $bySec[$sec].Add("$key=$v"); $taken[$k] = 1; $n++
  }
  $out = "$myDir\own-$(SafeName $m.Name).cfg"
  if ($n -eq 0) { if (Test-Path $out) { Remove-Item $out }; continue }
  $sb = New-Object Text.StringBuilder
  [void]$sb.AppendLine("; Copy of $($m.Name)'s own uk translation (tools/copy-own-uk.ps1). Do not edit: fix terms in terminology-fixes.cfg.")
  if ($bySec.Contains('')) { foreach ($l in $bySec['']) { [void]$sb.AppendLine($l) } }
  foreach ($s in $bySec.Keys) {
    if ($s -eq '') { continue }
    [void]$sb.AppendLine(''); [void]$sb.AppendLine("[$s]")
    foreach ($l in $bySec[$s]) { [void]$sb.AppendLine($l) }
  }
  [IO.File]::WriteAllText($out, $sb.ToString(), $utf8)
  "{0,-40} {1,5} keys" -f $m.Name, $n
  $total += $n
}
"--- copied: $total keys from $($modList.Count) mods"
