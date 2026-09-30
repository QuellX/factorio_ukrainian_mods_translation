$dir = 'E:\games\mods\locale\ukrainian-mods-translation\locale\uk'; $seen = @{}; $removed = 0
foreach ($f in Get-ChildItem $dir -Filter *.cfg | Sort-Object Name) {
  $sec = ''; $out = New-Object Collections.Generic.List[string]
  foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
    $t = $l.Trim()
    if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; $out.Add($l); continue }
    $i = $l.IndexOf('=')
    if ($i -ge 1) {
      $k = "$sec/" + $l.Substring(0, $i).Trim()
      if ($seen.ContainsKey($k)) {
        if ($seen[$k][0] -ne $l.Substring($i + 1)) { "VALUE DIFF $k in $($f.Name) vs $($seen[$k][1])" }
        $removed++; continue
      }
      $seen[$k] = @($l.Substring($i + 1), $f.Name)
    }
    $out.Add($l)
  }
  [IO.File]::WriteAllLines($f.FullName, $out, (New-Object Text.UTF8Encoding $false))
}
"cross-file duplicates removed: $removed"
# remove sections left empty and verify no repeated headers
foreach ($f in Get-ChildItem $dir -Filter *.cfg) {
  $lines = [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)
  $out = New-Object Collections.Generic.List[string]; $h = @{}
  for ($n = 0; $n -lt $lines.Count; $n++) {
    $l = $lines[$n]
    if ($l -match '^\[(.+)\]$') {
      if ($h.ContainsKey($matches[1])) { "STILL DUP $($f.Name) $($matches[1])" }
      $h[$matches[1]] = 1
      $j = $n + 1; while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
      if ($j -ge $lines.Count -or $lines[$j] -match '^\[') { continue }
    }
    $out.Add($l)
  }
  [IO.File]::WriteAllLines($f.FullName, $out, (New-Object Text.UTF8Encoding $false))
}
& (Join-Path $PSScriptRoot 'build-zip.ps1')
