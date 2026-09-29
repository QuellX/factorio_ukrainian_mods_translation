$dir = 'E:\games\mods\locale\ukrainian-mods-translation\locale'
foreach ($f in Get-ChildItem $dir -Recurse -Filter *.cfg) {
  $secs = [ordered]@{}; $secs[''] = [ordered]@{}
  $sec = ''; $dupSec = @{}; $seen = @{}; $dupKeys = @()
  foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
    $t = $l.TrimStart([char]0xFEFF).Trim()
    if ($t -eq '' -or $t[0] -eq ';' -or $t[0] -eq '#') { continue }
    if ($t -match '^\[(.+)\]$') {
      $sec = $matches[1].Trim()
      if ($seen.ContainsKey($sec)) { $dupSec[$sec] = 1 } else { $seen[$sec] = 1 }
      if (-not $secs.Contains($sec)) { $secs[$sec] = [ordered]@{} }
      continue
    }
    $i = $l.IndexOf('='); if ($i -lt 1) { "BAD LINE in $($f.Name): $l"; continue }
    $k = $l.Substring(0, $i).TrimStart([char]0xFEFF).Trim(); $v = $l.Substring($i + 1).TrimEnd()
    if ($secs[$sec].Contains($k)) { $dupKeys += "[$sec] $k" + $(if ($secs[$sec][$k] -ne $v) { ' (DIFFERENT VALUES, kept last)' } else { '' }) }
    $secs[$sec][$k] = $v
  }
  $sb = New-Object Text.StringBuilder
  foreach ($k in $secs[''].Keys) { [void]$sb.AppendLine("$k=$($secs[''][$k])") }
  foreach ($s in $secs.Keys) {
    if ($s -eq '' -or $secs[$s].Count -eq 0) { continue }
    if ($sb.Length -gt 0) { [void]$sb.AppendLine() }
    [void]$sb.AppendLine("[$s]")
    foreach ($k in $secs[$s].Keys) { [void]$sb.AppendLine("$k=$($secs[$s][$k])") }
  }
  [IO.File]::WriteAllText($f.FullName, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
  "{0}: merged sections [{1}]; duplicate keys: {2}" -f $f.Name, ($dupSec.Keys -join ', '), $(if ($dupKeys) { $dupKeys -join '; ' } else { 'none' })
}
