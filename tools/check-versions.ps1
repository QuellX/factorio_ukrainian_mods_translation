<#
Tracks which version of each mod the translation pack was made against.

  check-versions.ps1                 -> report mods that need (re)translation; exit code 1 if any
  check-versions.ps1 -Record a,b     -> mark mods a,b as translated at their current state
  check-versions.ps1 -Record -All    -> mark every mod in mods/ as translated at its current state

State file: translated-versions.json (repo root). For each mod it stores the mod version, a hash of
its English locale (catches text changes without a version bump), a hash of the mod's own Ukrainian
locale (if the author adds/changes uk, our overrides may become redundant or conflicting) and when
we last translated it.
#>
param([string[]]$Record, [switch]$All)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$modsDir = Join-Path $repo 'mods'
$stateFile = Join-Path $repo 'translated-versions.json'
$gameData = 'E:\games\steam\steamapps\common\Factorio\data'

function LocaleHash($dir) {
  if (-not (Test-Path $dir)) { return $null }
  $files = Get-ChildItem $dir -Filter *.cfg | Sort-Object Name
  if (-not $files) { return $null }
  $sha = [Security.Cryptography.SHA256]::Create(); $ms = New-Object IO.MemoryStream
  foreach ($f in $files) {
    $n = [Text.Encoding]::UTF8.GetBytes($f.Name + "`n"); $ms.Write($n, 0, $n.Length)
    $b = [IO.File]::ReadAllBytes($f.FullName); $ms.Write($b, 0, $b.Length)
  }
  (($sha.ComputeHash($ms.ToArray()) | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 16)
}
function KeyCount($dir) {
  if (-not (Test-Path $dir)) { return 0 }
  $n = 0
  foreach ($f in Get-ChildItem $dir -Filter *.cfg) {
    foreach ($l in [IO.File]::ReadAllLines($f.FullName)) { $t = $l.Trim(); if ($t -and $t[0] -ne ';' -and $t[0] -ne '#' -and $t[0] -ne '[' -and $t.Contains('=')) { $n++ } }
  }
  $n
}
function J($s) { if ($null -eq $s) { return 'null' }; '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"' }

# Current state of every mod in mods/
$current = [ordered]@{}
foreach ($d in Get-ChildItem $modsDir -Directory | Sort-Object Name) {
  $infoPath = Join-Path $d.FullName 'info.json'; if (-not (Test-Path $infoPath)) { continue }
  $info = Get-Content $infoPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $current[$info.name] = [ordered]@{
    folder = $d.Name; version = [string]$info.version
    enHash = LocaleHash (Join-Path $d.FullName 'locale\en'); enKeys = KeyCount (Join-Path $d.FullName 'locale\en')
    ownUkHash = LocaleHash (Join-Path $d.FullName 'locale\uk'); ownUkKeys = KeyCount (Join-Path $d.FullName 'locale\uk')
  }
}
$gameVersion = $null
if (Test-Path "$gameData\base\info.json") { $gameVersion = (Get-Content "$gameData\base\info.json" -Raw | ConvertFrom-Json).version }

# Previous state
$state = [ordered]@{}; $gameAtRecord = $null; $createdAt = $null
if (Test-Path $stateFile) {
  $old = Get-Content $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
  $gameAtRecord = $old.gameVersion; $createdAt = $old.createdAt
  foreach ($p in $old.mods.PSObject.Properties) { $h = [ordered]@{}; foreach ($q in $p.Value.PSObject.Properties) { $h[$q.Name] = $q.Value }; $state[$p.Name] = $h }
}

if ($Record -or $All) {
  $names = if ($All) { @($current.Keys) } else { $Record }
  $now = Get-Date -Format 'yyyy-MM-dd'
  foreach ($n in $names) {
    if (-not $current.Contains($n)) { Write-Warning "Unknown mod: $n (use the internal name from info.json)"; continue }
    $e = [ordered]@{}; foreach ($k in $current[$n].Keys) { $e[$k] = $current[$n][$k] }; $e['translatedAt'] = $now
    $state[$n] = $e; "recorded $n $($e.version)"
  }
  if (-not $createdAt) { $createdAt = $now }
  $sb = New-Object Text.StringBuilder
  [void]$sb.AppendLine('{')
  [void]$sb.AppendLine('  "about": "Mod versions the ukrainian-mods-translation pack was made against. Maintained by tools/check-versions.ps1 - do not edit by hand.",')
  [void]$sb.AppendLine('  "createdAt": ' + (J $createdAt) + ',')
  [void]$sb.AppendLine('  "updatedAt": ' + (J (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')) + ',')
  [void]$sb.AppendLine('  "gameVersion": ' + (J $(if ($Record -or $All) { $gameVersion } else { $gameAtRecord })) + ',')
  [void]$sb.AppendLine('  "mods": {')
  $rows = foreach ($n in ($state.Keys | Sort-Object { $_.ToLower() })) {
    $e = $state[$n]
    $fields = foreach ($k in 'folder','version','enHash','enKeys','ownUkHash','ownUkKeys','translatedAt') {
      $v = $e[$k]; (J $k) + ': ' + $(if ($v -is [int] -or $v -is [long]) { "$v" } else { J $v })
    }
    '    ' + (J $n) + ': { ' + ($fields -join ', ') + ' }'
  }
  [void]$sb.AppendLine(($rows -join ",`r`n")); [void]$sb.AppendLine('  }'); [void]$sb.AppendLine('}')
  [IO.File]::WriteAllText($stateFile, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
  "saved $stateFile"
  return
}

# Report
$needs = 0
if ($gameAtRecord -and $gameVersion -and $gameAtRecord -ne $gameVersion) { "GAME     Factorio $gameAtRecord -> $gameVersion : official terminology may have changed, rerun tools/gloss.ps1"; $needs++ }
foreach ($n in $current.Keys) {
  $c = $current[$n]
  if (-not $state.Contains($n)) {
    if ($c.enHash) { "NEW      $n $($c.version) ($($c.enKeys) en keys) : not translated yet"; $needs++ } else { "NEW      $n $($c.version) : no locale, nothing to translate (record it)" }
    continue
  }
  $s = $state[$n]; $why = @()
  if ($s.version -ne $c.version) { $why += "version $($s.version) -> $($c.version)" }
  if ($s.enHash -ne $c.enHash) { $why += "English text changed ($($s.enKeys) -> $($c.enKeys) keys)" }
  if ($s.ownUkHash -ne $c.ownUkHash) { $why += "mod's own uk changed ($($s.ownUkKeys) -> $($c.ownUkKeys) keys): check pack for now-redundant/conflicting keys" }
  if ($why) {
    $textChanged = ($s.enHash -ne $c.enHash) -or ($s.ownUkHash -ne $c.ownUkHash)
    $tag = if ($textChanged) { 'UPDATE  ' } else { 'VERSION ' }
    "$tag $n : $($why -join '; ')"
    if ($textChanged) { $needs++ }
  }
}
foreach ($n in $state.Keys) { if (-not $current.Contains($n)) { "REMOVED  $n $($state[$n].version) : no longer installed; its keys in the pack can be dropped" } }
if ($needs) { "--- $needs mod(s) need translation work"; exit 1 } else { '--- all mods up to date' }
