$todo = 'C:\Users\Quell\AppData\Local\Temp\claude\e--games-mods-locale\bf32b9ea-cda8-4c9f-843f-c0813c9fa4c3\scratchpad\todo\bobenemies.cfg'
$out = 'C:\Users\Quell\AppData\Local\Temp\claude\e--games-mods-locale\bf32b9ea-cda8-4c9f-843f-c0813c9fa4c3\scratchpad\enemies-gen.cfg'
$m = @{ small='Малий'; medium='Середній'; big='Великий'; huge='Величезний'; giant='Велетенський'; titan='Титанічний'; behemoth='Гігантський' }
$f = @{ small='Мала'; medium='Середня'; big='Велика'; huge='Величезна'; giant='Велетенська'; titan='Титанічна'; behemoth='Гігантська' }
$tm = @{ piercing='бронебійний'; electric='електричний'; acid='кислотний'; explosive='вибуховий'; poison='отруйний'; fire='вогняний' }
$tf = @{ piercing='бронебійна'; electric='електрична'; acid='кислотна'; explosive='вибухова'; poison='отруйна'; fire='вогняна' }
$tpl = @{ piercing='бронебійних'; electric='електричних'; acid='кислотних'; explosive='вибухових'; poison='отруйних'; fire='вогняних' }
function Cap($s) { $s.Substring(0,1).ToUpper() + $s.Substring(1) }
$sb = New-Object Text.StringBuilder
$lines = [IO.File]::ReadAllLines($todo, [Text.Encoding]::UTF8)
$in = $false
foreach ($l in $lines) {
  if ($l -eq '[entity-name]') { $in = $true; continue }
  if ($l.StartsWith('[')) { $in = $false }
  if (-not $in -or $l -notmatch '^(bob-[^=]+)=') { continue }
  $k = $matches[1]; $v = $null
  if ($k -match '^bob-(small|medium|big|huge|giant|titan|behemoth)-(\w+)-(biter|spitter|worm-turret)$') {
    $s = $matches[1]; $t = $matches[2]; $kind = $matches[3]
    switch ($kind) {
      'biter' { $v = "$($m[$s]) $($tm[$t]) кусака" }
      'spitter' { $v = "$($f[$s]) $($tf[$t]) плювака" }
      'worm-turret' { $v = "$($m[$s]) $($tm[$t]) черв'як" }
    }
  } elseif ($k -match '^bob-leviathan-(\w+)-(biter|spitter|worm-turret)$') {
    $t = $matches[1]; $kind = $matches[2]
    switch ($kind) {
      'biter' { $v = "$(Cap $tm[$t]) кусака-левіафан" }
      'spitter' { $v = "$(Cap $tf[$t]) плювака-левіафан" }
      'worm-turret' { $v = "$(Cap $tm[$t]) черв'як-левіафан" }
    }
  } elseif ($k -match '^bob-(huge|giant)-(biter|spitter|worm-turret)$') {
    $s = $matches[1]
    switch ($matches[2]) { 'biter' { $v = "$($m[$s]) кусака" } 'spitter' { $v = "$($f[$s]) плювака" } 'worm-turret' { $v = "$($m[$s]) черв'як" } }
  } elseif ($k -match '^bob-titan-worm-turret$') { $v = "Титанічний черв'як" }
  elseif ($k -match '^bob-leviathan-worm-turret$') { $v = "Черв'як-левіафан" }
  elseif ($k -match '^bob-0-(\w+)-(biter|spitter)-spawner$') {
    $v = "Знесилене лігво $($tpl[$matches[1]]) " + $(if ($matches[2] -eq 'biter') { 'кусак' } else { 'плювак' })
  } elseif ($k -match '^bob-(\w+)-(biter|spitter)-spawner$' -and $tpl.ContainsKey($matches[1])) {
    $v = "Лігво $($tpl[$matches[1]]) " + $(if ($matches[2] -eq 'biter') { 'кусак' } else { 'плювак' })
  } elseif ($k -match '^bob-(\w+)-super-spawner$' -and $tpl.ContainsKey($matches[1])) {
    $v = "Материнське лігво ($($tf[$matches[1]]) порода)"
  }
  if ($v) { [void]$sb.AppendLine("$k=$v") }
}
[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
