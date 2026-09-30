$ErrorActionPreference = 'Stop'
# Package ukrainian-mods-translation/ into <Factorio mods>\ukrainian-mods-translation_<version>.zip
# (version from info.json). Older versions of our zip there are deleted so Factorio sees only one.
$src = 'E:\games\mods\locale\ukrainian-mods-translation'
$dest = 'E:\games\mods\Factorio'
$info = [IO.File]::ReadAllText("$src\info.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
$zip = Join-Path $dest "$($info.name)_$($info.version).zip"
Get-ChildItem $dest -Filter "$($info.name)_*.zip" | Where-Object { $_.FullName -ne $zip } | ForEach-Object { [IO.File]::Delete($_.FullName); "removed old $($_.Name)" }
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
if (Test-Path $zip) { [IO.File]::Delete($zip) }
$z = [IO.Compression.ZipFile]::Open($zip, 'Create')
try {
  Get-ChildItem $src -Recurse -File | ForEach-Object { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $_.FullName, "$($info.name)/" + $_.FullName.Substring($src.Length + 1).Replace('\', '/')) }
} finally { $z.Dispose() }
"zip rebuilt: $zip ($((Get-Item $zip).Length) bytes)"
