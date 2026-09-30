<#
For the given mods (internal names; default = all mods check-versions reports as NEW/UPDATE is NOT known here,
so pass -Mods explicitly or -AllNew to use every mod missing from translated-versions.json):
  <Out>\todo\<mod>.cfg      English keys with no Ukrainian anywhere (mod's own uk, any other mod's uk such as
                            language packs, or our pack), or whose uk equals English -> translate these
  <Out>\existing\<mod>.cfg  keys that already have Ukrainian from somewhere else, written as
                            key=<uk>   preceded by  ;EN <english>   -> review for terminology
Prints a summary table.
#>
param([string[]]$Mods, [switch]$AllNew, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$modsDir = Join-Path $repo 'mods'
$packDir = Join-Path $repo 'ukrainian-mods-translation\locale\uk'

function ParseDir($dir, $h, $tag) {
  if (-not (Test-Path $dir)) { return }
  foreach ($f in Get-ChildItem $dir -Filter *.cfg | Sort-Object Name) {
    $sec = ''
    foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      $t = $l.TrimStart([char]0xFEFF).Trim()
      if ($t -eq '' -or $t[0] -eq ';' -or $t[0] -eq '#') { continue }
      if ($t -match '^\[(.+)\]$') { $sec = $matches[1].Trim(); continue }
      $i = $l.IndexOf('='); if ($i -lt 1) { continue }
      $k = "$sec`t" + $l.Substring(0, $i).TrimStart([char]0xFEFF).Trim()
      if ($null -ne $tag) { if (-not $h.Contains($k)) { $h[$k] = @($l.Substring($i + 1), $tag) } } else { $h[$k] = $l.Substring($i + 1) }
    }
  }
}

$info = @{}
foreach ($d in Get-ChildItem $modsDir -Directory | Where-Object { $_.Name -notlike 'ukrainian-mods-translation*' }) {
  $p = Join-Path $d.FullName 'info.json'; if (Test-Path $p) { $info[(Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json).name] = $d.FullName }
}
if ($AllNew) {
  $known = @{}
  $sf = Join-Path $repo 'translated-versions.json'
  if (Test-Path $sf) { (Get-Content $sf -Raw -Encoding UTF8 | ConvertFrom-Json).mods.PSObject.Properties | ForEach-Object { $known[$_.Name] = 1 } }
  $Mods = @($info.Keys | Where-Object { -not $known.ContainsKey($_) } | Sort-Object)
}

# Global uk: our pack first (highest priority, loads last), then every mod's uk
$ukAll = [ordered]@{}
ParseDir $packDir $ukAll 'pack'
foreach ($n in $info.Keys | Sort-Object) { ParseDir (Join-Path $info[$n] 'locale\uk') $ukAll $n }

New-Item -ItemType Directory -Force "$Out\todo", "$Out\existing" | Out-Null
$enc = New-Object Text.UTF8Encoding $false
$rows = @()
foreach ($n in $Mods) {
  if (-not $info.ContainsKey($n)) { Write-Warning "unknown mod $n"; continue }
  $en = [ordered]@{}; ParseDir (Join-Path $info[$n] 'locale\en') $en $null
  if ($en.Count -eq 0) { continue }
  $own = [ordered]@{}; ParseDir (Join-Path $info[$n] 'locale\uk') $own $null
  $todo = New-Object Text.StringBuilder; $ex = New-Object Text.StringBuilder
  $cT = ''; $cE = ''; $nT = 0; $nE = 0; $src = @{}
  foreach ($k in $en.Keys) {
    $v = $en[$k]; if ($v.Trim() -eq '') { continue }
    $p = $k.Split("`t", 2)
    $uk = $null; $from = $null
    if ($own.Contains($k)) { $uk = $own[$k]; $from = 'own' } elseif ($ukAll.Contains($k)) { $uk = $ukAll[$k][0]; $from = $ukAll[$k][1] }
    $has = $uk -and $uk.Trim() -ne '' -and -not ($uk -ceq $v -and $v -match '[a-zA-Z]{3}')
    if ($has) {
      if ($p[0] -ne $cE) { if ($cE -ne '') { [void]$ex.AppendLine() }; [void]$ex.AppendLine("[$($p[0])]"); $cE = $p[0] }
      [void]$ex.AppendLine(";EN $v"); [void]$ex.AppendLine("$($p[1])=$uk"); $nE++; $src[$from] = 1 + $src[$from]
    } else {
      if ($p[0] -ne $cT) { if ($cT -ne '') { [void]$todo.AppendLine() }; [void]$todo.AppendLine("[$($p[0])]"); $cT = $p[0] }
      [void]$todo.AppendLine("$($p[1])=$v"); $nT++
    }
  }
  if ($nT) { [IO.File]::WriteAllText("$Out\todo\$n.cfg", $todo.ToString(), $enc) }
  if ($nE) { [IO.File]::WriteAllText("$Out\existing\$n.cfg", $ex.ToString(), $enc) }
  $rows += [pscustomobject]@{ Mod = $n; En = $en.Count; Missing = $nT; HasUk = $nE; UkFrom = (($src.Keys | Sort-Object) -join ',') }
}
$rows | Format-Table -AutoSize | Out-String -Width 200
"TOTAL missing: $(($rows | Measure-Object Missing -Sum).Sum)   existing uk: $(($rows | Measure-Object HasUk -Sum).Sum)"
