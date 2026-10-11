param([Parameter(Mandatory)][string]$Pattern, [switch]$Key)
# Search the official game locale (all name/description sections) for English text (or key with -Key) matching
# the regex, print  section/key | en | uk. Use it to find the official term for something not in glossary-official.txt.
$ErrorActionPreference = 'Stop'
$game = 'E:\games\steam\steamapps\common\Factorio\data'
function Load($lang) {
  $h = [ordered]@{}
  foreach ($p in 'core','base','space-age','quality','elevated-rails','recycler') {
    foreach ($f in Get-ChildItem "$game\$p\locale\$lang" -Filter *.cfg -ErrorAction SilentlyContinue) {
      $sec = ''
      foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
        if ($l -match '^\[(.+)\]$') { $sec = $matches[1]; continue }
        $i = $l.IndexOf('='); if ($i -lt 1 -or $l.StartsWith(';')) { continue }
        $h["$sec/" + $l.Substring(0, $i)] = $l.Substring($i + 1)
      }
    }
  }
  $h
}
$en = Load 'en'; $uk = Load 'uk'
foreach ($k in $en.Keys) {
  $target = if ($Key) { $k } else { $en[$k] }
  if ($target -match $Pattern) { "$k | $($en[$k]) | $($uk[$k])" }
}
