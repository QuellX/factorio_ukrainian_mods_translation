$ErrorActionPreference = 'Stop'
$root = 'E:\games\mods\locale\mods'
$outDir = 'E:\games\mods\locale\ukrainian-mods-translation\locale\uk'
function ParseFile($f, $h, $tag) {
  $sec = ''
  foreach ($line in [IO.File]::ReadAllLines($f, [Text.Encoding]::UTF8)) {
    $t = $line.TrimStart([char]0xFEFF).Trim()
    if ($t -eq '' -or $t.StartsWith(';') -or $t.StartsWith('#')) { continue }
    if ($t -match '^\[(.+)\]$') { $sec = $matches[1].Trim(); continue }
    $i = $line.IndexOf('='); if ($i -lt 1) { continue }
    $k = "$sec`t" + $line.Substring(0,$i).TrimStart([char]0xFEFF).Trim()
    $v = $line.Substring($i+1)
    if ($null -ne $tag) {
      if ($h.Contains($k) -and $h[$k][0] -ne $v) { "CONFLICT $($k.Replace("`t",' / ')) :: $($h[$k][1]) = $($h[$k][0]) || $tag = $v" }
      $h[$k] = @($v, $tag)
    } else { $h[$k] = $v }
  }
}
$mine = [ordered]@{}
foreach ($f in Get-ChildItem $outDir -Filter *.cfg) { ParseFile $f.FullName $mine $f.Name }
"--- my keys: $($mine.Count)"
# coverage
$total = 0
foreach ($m in Get-ChildItem $root -Directory) {
  $en = Join-Path $m.FullName 'locale\en'; if (-not (Test-Path $en)) { continue }
  $e = [ordered]@{}; foreach ($f in Get-ChildItem $en -Filter *.cfg) { ParseFile $f.FullName $e $null }
  $u = @{}; $ud = Join-Path $m.FullName 'locale\uk'; if (Test-Path $ud) { foreach ($f in Get-ChildItem $ud -Filter *.cfg) { ParseFile $f.FullName $u $null } }
  foreach ($k in $e.Keys) {
    $v = $e[$k]
    $stripped = [regex]::Replace($v, '__[A-Z_]+__[^_]*?__|__\d+__|\[[^\]]*\]|__plural[^}]*}__|\\n', '')
    if ($stripped -notmatch '[A-Za-z]{2}') { continue }
    $has = ($u.Contains($k) -and $u[$k].Trim() -ne '' -and -not ($u[$k] -ceq $v)) -or $mine.Contains($k)
    if (-not $has) { $total++; "MISSING $($m.Name) :: $($k.Replace("`t",' / ')) = $v" }
  }
}
"--- missing: $total"
