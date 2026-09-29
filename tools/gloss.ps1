param([string]$Out)
$d = 'E:\games\steam\steamapps\common\Factorio\data'
function Parse($file) {
  $h = [ordered]@{}; $sec = ''
  foreach ($line in [IO.File]::ReadAllLines($file, [Text.Encoding]::UTF8)) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith(';') -or $t.StartsWith('#')) { continue }
    if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; continue }
    $i = $line.IndexOf('='); if ($i -lt 1) { continue }
    $h["$sec`t$($line.Substring(0,$i).Trim())"] = $line.Substring($i+1)
  }
  $h
}
$sections = 'item-name','entity-name','fluid-name','technology-name','recipe-name','equipment-name','tile-name','space-location-name','item-group-name','ammo-category-name','damage-type-name','virtual-signal-name','mod-setting-name','shortcut-name','quality-name','asteroid-chunk-name','surface-property-name','autoplace-control-names','achievement-name','controls','gui','gui-map-generator','description'
$seen = @{}
$sb = New-Object Text.StringBuilder
foreach ($pair in @(@('base','base'),@('space-age','space-age'),@('quality','quality'),@('elevated-rails','elevated-rails'),@('recycler','recycler'),@('core','core'))) {
  $en = Parse "$d\$($pair[0])\locale\en\$($pair[1]).cfg"
  $uk = Parse "$d\$($pair[0])\locale\uk\$($pair[1]).cfg"
  foreach ($k in $en.Keys) {
    $s = $k.Split("`t")[0]
    if ($sections -notcontains $s) { continue }
    if (-not $uk.Contains($k)) { continue }
    $e = $en[$k]; $u = $uk[$k]
    if ($e.Length -gt 60 -or $e -match '__|\\n') { continue }
    if ($seen.ContainsKey($e)) { continue }; $seen[$e] = 1
    [void]$sb.AppendLine("$e => $u")
  }
}
[IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
