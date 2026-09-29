$root = 'E:\games\mods\locale'; $out = "$root\ukrainian-mods-translation\locale\uk"
function P($f, $h, $tag) { $sec = ''; foreach ($l in [IO.File]::ReadAllLines($f, [Text.Encoding]::UTF8)) { $t = $l.TrimStart([char]0xFEFF).Trim(); if ($t -eq '' -or $t[0] -eq ';') { continue }; if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; continue }; $i = $l.IndexOf('='); if ($i -lt 1) { continue }; $h["$sec/" + $l.Substring(0, $i).Trim()] = @($l.Substring($i + 1), $tag) } }
$en = @{}; Get-ChildItem "$root\mods" -Directory | % { $d = Join-Path $_.FullName 'locale\en'; if (Test-Path $d) { Get-ChildItem $d -Filter *.cfg | % { P $_.FullName $en $null } } }
$mine = @{}; Get-ChildItem $out -Filter *.cfg | % { P $_.FullName $mine $_.Name }
foreach ($k in $mine.Keys | Sort-Object) {
  $e = if ($en.ContainsKey($k)) { $en[$k][0] } else { '' }
  $u = $mine[$k][0]
  if ($e -match '(?i)smelt' -or $u -match '(?i)плав') { "{0} | {1}`n   EN: {2}`n   UK: {3}" -f $mine[$k][1], $k, $e, $u }
}
