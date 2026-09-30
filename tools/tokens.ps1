$root = 'E:\games\mods\locale\mods'; $out = 'E:\games\mods\locale\ukrainian-mods-translation\locale\uk'
function P($f, $h) { $sec = ''; foreach ($l in [IO.File]::ReadAllLines($f, [Text.Encoding]::UTF8)) { $t = $l.TrimStart([char]0xFEFF).Trim(); if ($t -eq '' -or $t[0] -eq ';' -or $t[0] -eq '#') { continue }; if ($t -match '^\[(.+)\]$') { $sec = $matches[1]; continue }; $i = $l.IndexOf('='); if ($i -lt 1) { continue }; $k = "$sec/" + $l.Substring(0, $i).TrimStart([char]0xFEFF).Trim(); if (-not $h.ContainsKey($k)) { $h[$k] = New-Object Collections.Generic.List[string] }; $h[$k].Add($l.Substring($i + 1)) } }
$en = @{}
Get-ChildItem $root -Directory | Where-Object { $_.Name -notlike 'ukrainian-mods-translation*' } | % { $d = Join-Path $_.FullName 'locale\en'; if (Test-Path $d) { Get-ChildItem $d -Filter *.cfg | % { P $_.FullName $en } } }
$mine = @{}; Get-ChildItem $out -Filter *.cfg | % { P $_.FullName $mine }
$rx = '__[A-Z_]+__(?:[0-9]+__)?[A-Za-z0-9_\-\.]*?__|__\d+__|\[(?:img|item|entity|fluid|technology|recipe|planet|space-location|tile|quality|virtual-signal|tooltip|font|color|/font|/color)[^\]]*\]|\\n|__plural_for_parameter__\d+__'
function Toks($s) { ([regex]::Matches($s, $rx) | % { $_.Value -replace '^\[tooltip=[^,]*,', '[tooltip=,' -replace '^\[(font|color)=.*', '[$1]' }) | Sort-Object }
$bad = 0
foreach ($k in $mine.Keys) {
  if (-not $en.ContainsKey($k)) { "NO-EN $k"; continue }
  $u = $mine[$k][$mine[$k].Count - 1]
  $ok = $false
  foreach ($e in $en[$k]) { if (((Toks $e) -join '|') -eq ((Toks $u) -join '|')) { $ok = $true; break } }
  if (-not $ok) { $bad++; "TOKENS $k`n  EN: $($en[$k][0])`n  UK: $u" }
}
"--- token mismatches: $bad"
