param([string]$Root = 'E:\games\mods\locale\mods', [string]$Out)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Out | Out-Null

function Parse-Dir($dir) {
  # returns ordered dict "section`tkey" -> value
  $h = [ordered]@{}
  if (-not (Test-Path $dir)) { return $h }
  foreach ($f in Get-ChildItem $dir -File -Filter *.cfg | Sort-Object Name) {
    $sec = ''
    foreach ($line in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      $t = $line.TrimStart([char]0xFEFF).Trim()
      if ($t -eq '' -or $t.StartsWith(';') -or $t.StartsWith('#')) { continue }
      if ($t -match '^\[(.+)\]$') { $sec = $matches[1].Trim(); continue }
      $i = $line.IndexOf('=')
      if ($i -lt 1) { continue }
      $k = $line.Substring(0, $i).TrimStart([char]0xFEFF).Trim()
      $v = $line.Substring($i + 1)
      $h["$sec`t$k"] = $v
    }
  }
  return $h
}

$summary = @()
foreach ($m in Get-ChildItem $Root -Directory) {
  $loc = Join-Path $m.FullName 'locale'
  if (-not (Test-Path (Join-Path $loc 'en'))) { continue }
  $en = Parse-Dir (Join-Path $loc 'en')
  $uk = Parse-Dir (Join-Path $loc 'uk')
  $missing = [ordered]@{}
  foreach ($k in $en.Keys) {
    $v = $en[$k]
    if ($v.Trim() -eq '') { continue }
    if (-not $uk.Contains($k) -or $uk[$k].Trim() -eq '' -or ($uk[$k] -ceq $v -and $v -match '[a-zA-Z]{3}')) { $missing[$k] = $v }
  }
  $summary += '{0}`t{1}`t{2}`t{3}' -f $m.Name, $en.Count, $uk.Count, $missing.Count
  if ($missing.Count -eq 0) { continue }
  $sb = New-Object Text.StringBuilder
  $cur = $null
  foreach ($k in $missing.Keys) {
    $p = $k.Split("`t", 2)
    if ($p[0] -ne $cur) { if ($null -ne $cur) { [void]$sb.AppendLine() }; if ($p[0] -ne '') { [void]$sb.AppendLine("[$($p[0])]") }; $cur = $p[0] }
    [void]$sb.AppendLine("$($p[1])=$($missing[$k])")
  }
  [IO.File]::WriteAllText((Join-Path $Out "$($m.Name).cfg"), $sb.ToString(), (New-Object Text.UTF8Encoding $false))
}
$summary
