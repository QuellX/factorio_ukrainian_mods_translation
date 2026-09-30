param([string]$Version)
$ErrorActionPreference = 'Stop'
# Add every mod in mods\ to info.json as a hidden optional dependency "(?) name" (keeps existing ones),
# so the pack loads after all of them. -Version also sets info.json "version".
$p = 'E:\games\mods\locale\ukrainian-mods-translation\info.json'
$j = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) | ConvertFrom-Json
$names = New-Object System.Collections.Generic.SortedSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($d in @($j.dependencies)) { if ($d -match '^\(\?\)\s*(.+?)\s*$') { [void]$names.Add($matches[1]) } }
$before = $names.Count
foreach ($m in Get-ChildItem 'E:\games\mods\locale\mods' -Directory) {
  $ij = Join-Path $m.FullName 'info.json'; if (-not (Test-Path $ij)) { continue }
  $n = ([IO.File]::ReadAllText($ij, [Text.Encoding]::UTF8) | ConvertFrom-Json).name
  if ($n -and $n -ne $j.name) { if ($names.Add($n)) { "added: $n" } }
}
$j.dependencies = @('base >= 2.1') + @($names | ForEach-Object { "(?) $_" })
if ($Version) { $j.version = $Version }
[IO.File]::WriteAllText($p, ($j | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
"deps: $before -> $($names.Count); version $($j.version)"
