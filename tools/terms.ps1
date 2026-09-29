$ErrorActionPreference = 'Stop'
$root = 'E:\games\mods\locale'
$myDir = "$root\ukrainian-mods-translation\locale\uk"
$game = 'E:\games\steam\steamapps\common\Factorio\data'
$outFile = "$root\terminology-uk.json"

$nameSections = @('item-name','entity-name','fluid-name','recipe-name','technology-name','equipment-name','tile-name',
  'space-location-name','space-connection-name','item-group-name','autoplace-control-names','achievement-name',
  'ammo-category-name','fuel-category-name','surface-property-name','decorative-name','module-category-name',
  'recipe-category-name','virtual-signal-name','remnant-name','quality-name','asteroid-chunk-name','damage-type-name')

function ParseDir($dir) {
  $h = [ordered]@{}
  if (-not (Test-Path $dir)) { return $h }
  foreach ($f in Get-ChildItem $dir -Filter *.cfg | Sort-Object Name) {
    $sec = ''
    foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      $t = $l.TrimStart([char]0xFEFF).Trim()
      if ($t -eq '' -or $t[0] -eq ';' -or $t[0] -eq '#') { continue }
      if ($t -match '^\[(.+)\]$') { $sec = $matches[1].Trim(); continue }
      $i = $l.IndexOf('='); if ($i -lt 1) { continue }
      $h["$sec`t" + $l.Substring(0, $i).TrimStart([char]0xFEFF).Trim()] = $l.Substring($i + 1).Trim()
    }
  }
  return $h
}

# Keys where this mod's English text is replaced by a later-loading mod (resolved during translation).
$overridden = @{
  'Accumulator-V2' = @{ winner = 'Paracelsin'; keys = @('entity-name/accumulator-v2','technology-name/accumulator-v2') }
  'SolarMatrix' = @{ winner = 'Paracelsin'; keys = @('technology-name/solar-matrix') }
  'elevated-pipes' = @{ winner = 'Paracelsin'; keys = @('technology-name/elevated-pipe') }
  'angelssmelting' = @{ winner = 'planet-muluna'; keys = @('item-name/copper-cable') }
  'planetaris-arig' = @{ winner = 'angelbob-spaceage-rebalance'; keys = @('item-name/planetaris-big-chest','item-name/planetaris-heavy-glass','item-name/planetaris-raw-quartz','item-name/planetaris-silica','entity-name/planetaris-big-chest','entity-name/planetaris-active-provider-big-chest','entity-name/planetaris-passive-provider-big-chest','entity-name/planetaris-storage-big-chest','entity-name/planetaris-buffer-big-chest','entity-name/planetaris-requester-big-chest','technology-name/planetaris-glass','technology-name/planetaris-heavy-glass','technology-name/planetaris-big-chest') }
}

$mine = ParseDir $myDir

# Global lookup (en + effective uk) to resolve __ITEM__x__ / __ENTITY__x__ style references
$globEn = @{}; $globUk = @{}
foreach ($p in @('base','space-age','quality','elevated-rails','recycler','core')) {
  $e = ParseDir "$game\$p\locale\en"; $u = ParseDir "$game\$p\locale\uk"
  foreach ($k in $e.Keys) { $globEn[$k] = $e[$k] }; foreach ($k in $u.Keys) { $globUk[$k] = $u[$k] }
}
$mods = @()
foreach ($d in Get-ChildItem "$root\mods" -Directory | Where-Object { $_.Name -ne 'ukrainian-mods-translation' }) {
  $info = Get-Content "$($d.FullName)\info.json" -Raw -Encoding UTF8 | ConvertFrom-Json
  $e = ParseDir "$($d.FullName)\locale\en"; if ($e.Count -eq 0) { continue }
  $u = ParseDir "$($d.FullName)\locale\uk"
  foreach ($k in $e.Keys) { $globEn[$k] = $e[$k] }; foreach ($k in $u.Keys) { $globUk[$k] = $u[$k] }
  $mods += [pscustomobject]@{ Name = $info.name; Title = $info.title; En = $e; Uk = $u }
}
foreach ($k in $mine.Keys) { $globUk[$k] = $mine[$k] }

$secFor = @{ ITEM='item-name'; ENTITY='entity-name'; FLUID='fluid-name'; TECHNOLOGY='technology-name'; RECIPE='recipe-name'; EQUIPMENT='equipment-name'; TILE='tile-name'; SPACE_LOCATION='space-location-name' }
function Resolve($s, $tbl, $depth) {
  if ($depth -gt 4) { return $s }
  return [regex]::Replace($s, '__(ITEM|ENTITY|FLUID|TECHNOLOGY|RECIPE|EQUIPMENT|TILE|SPACE_LOCATION)__([A-Za-z0-9_\-\.]+)__', {
    param($m) $k = $secFor[$m.Groups[1].Value] + "`t" + $m.Groups[2].Value
    if ($tbl.ContainsKey($k)) { Resolve $tbl[$k] $tbl ($depth + 1) } else { $m.Value } })
}

function J($s) {
  $sb = New-Object Text.StringBuilder '"'
  foreach ($c in $s.ToCharArray()) {
    switch ($c) { '"' { [void]$sb.Append('\"') } '\' { [void]$sb.Append('\\') } default { if ([int]$c -lt 32) { [void]$sb.AppendFormat('\u{0:x4}', [int]$c) } else { [void]$sb.Append($c) } } }
  }
  [void]$sb.Append('"'); $sb.ToString()
}

$w = New-Object Text.StringBuilder
[void]$w.AppendLine('{')
[void]$w.AppendLine('  "_about": {')
[void]$w.AppendLine('    "description": ' + (J 'English → Ukrainian terminology (names of items, entities, fluids, recipes, technologies, etc.) for every installed mod, grouped by mod and category. "uk" is the text the game shows with ukrainian-mods-translation installed; "source" says where it comes from.') + ',')
[void]$w.AppendLine('    "sources": { "official": "Factorio official Ukrainian locale", "mod": "the mod''s own Ukrainian locale", "translation-pack": "ukrainian-mods-translation", "resolved-reference": "name built from references to other translated names (e.g. __ITEM__x__ MK2)" },')
# createdAt is kept from the previous file (old files used "generated"); updatedAt is always now
$createdAt = $null
if (Test-Path $outFile) {
  $m = [regex]::Match([IO.File]::ReadAllText($outFile, [Text.Encoding]::UTF8), '"(?:createdAt|generated)":\s*"([^"]+)"')
  if ($m.Success) { $createdAt = $m.Groups[1].Value }
}
$nowStamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
if (-not $createdAt) { $createdAt = $nowStamp }
[void]$w.AppendLine('    "createdAt": ' + (J $createdAt) + ',')
[void]$w.AppendLine('    "updatedAt": ' + (J $nowStamp))
[void]$w.AppendLine('  },')

$groups = @()
# Official game terminology first
foreach ($p in @('base','space-age','quality','elevated-rails','recycler')) {
  $e = ParseDir "$game\$p\locale\en"; $u = ParseDir "$game\$p\locale\uk"
  $groups += [pscustomobject]@{ Name = $p; Title = "Factorio: $p (official)"; En = $e; Uk = $u; Official = $true }
}
$groups += $mods | Sort-Object { $_.Name.ToLower() } | ForEach-Object { $_ | Add-Member Official $false -PassThru }

$modBlocks = @(); $total = 0
foreach ($g in $groups) {
  $bySec = [ordered]@{}
  foreach ($k in $g.En.Keys) {
    $parts = $k.Split("`t", 2); $sec = $parts[0]; $key = $parts[1]
    if ($nameSections -notcontains $sec) { continue }
    $en = Resolve $g.En[$k] $globEn 0
    if ($en -notmatch '[A-Za-z]{2}' -or $en -match '__[A-Z_]+__') { continue }
    $entry = [ordered]@{ en = $en }
    $ov = if (-not $g.Official -and $overridden.ContainsKey($g.Name) -and $overridden[$g.Name].keys -contains "$sec/$key") { $overridden[$g.Name].winner } else { $null }
    if ($ov) {
      if ($g.Uk.Contains($k)) { $entry.uk = Resolve $g.Uk[$k] $globUk 0; $entry.source = 'mod' }
      $entry.note = "In game this name is replaced by $ov"
    } elseif ($g.Official) {
      if (-not $g.Uk.Contains($k)) { continue }
      $entry.uk = $g.Uk[$k]; $entry.source = 'official'
    } elseif ($mine.Contains($k)) {
      $entry.uk = Resolve $mine[$k] $globUk 0; $entry.source = 'translation-pack'
    } elseif ($g.Uk.Contains($k) -and $g.Uk[$k] -cne $g.En[$k]) {
      $entry.uk = Resolve $g.Uk[$k] $globUk 0; $entry.source = 'mod'
    } elseif ($g.En[$k] -match '__[A-Z_]+__') {
      $entry.uk = Resolve $g.En[$k] $globUk 0; $entry.source = 'resolved-reference'
    } elseif ($globUk.ContainsKey($k)) {
      $entry.uk = Resolve $globUk[$k] $globUk 0; $entry.source = 'official'
    } else { continue }
    if ($entry.uk -match '__[A-Z_]+__') { continue }
    if (-not $bySec.Contains($sec)) { $bySec[$sec] = [ordered]@{} }
    $bySec[$sec][$key] = $entry; $total++
  }
  if ($bySec.Count -eq 0) { continue }
  $b = New-Object Text.StringBuilder
  [void]$b.AppendLine('    ' + (J $g.Name) + ': {')
  [void]$b.AppendLine('      "title": ' + (J ([string]$g.Title)) + ',')
  $secLines = @()
  foreach ($s in $bySec.Keys) {
    $sl = New-Object Text.StringBuilder
    [void]$sl.AppendLine('      ' + (J $s) + ': {')
    $items = @()
    foreach ($key in $bySec[$s].Keys) {
      $en = $bySec[$s][$key]
      $fields = @(); foreach ($f in $en.Keys) { $fields += (J $f) + ': ' + (J $en[$f]) }
      $items += '        ' + (J $key) + ': { ' + ($fields -join ', ') + ' }'
    }
    [void]$sl.Append(($items -join ",`r`n") + "`r`n      }")
    $secLines += $sl.ToString()
  }
  [void]$b.Append(($secLines -join ",`r`n") + "`r`n    }")
  $modBlocks += $b.ToString()
}
[void]$w.AppendLine('  "mods": {')
[void]$w.Append(($modBlocks -join ",`r`n") + "`r`n  }`r`n}`r`n")
[IO.File]::WriteAllText($outFile, $w.ToString(), (New-Object Text.UTF8Encoding $false))
"groups: $($modBlocks.Count), terms: $total"
