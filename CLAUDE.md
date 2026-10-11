# Ukrainian translation pack for the user's Factorio mods

This folder (`E:\games\mods\locale`) is a git repo (remote `git@github.com:QuellX/factorio_ukrainian_mods_translation.git`) holding the translation mod we build. **Unpacked copies** of the user's Factorio mods (one folder each, read-only reference, plus `mod-list.json`/`mod-settings.dat`) live in `mods/`, which is git-ignored — never commit third-party mod files. A copy of our own mod may also sit there (`mods/ukrainian-mods-translation*`); every tool skips it. Archives (`*.zip`, `*.7z`, `*.rar`) are git-ignored too.

- Our mod: `ukrainian-mods-translation/` (source). Packaged zip goes to the real mods folder: `E:\games\mods\Factorio\ukrainian-mods-translation_<version>.zip` (current 1.4.0; close Factorio first — a running game locks the zip; `build-zip.ps1` deletes older versions of our zip there).
- Official game locale (terminology source of truth): `E:\games\steam\steamapps\common\Factorio\data\{base,space-age,quality,elevated-rails,recycler,core}\locale\{en,uk}\*.cfg`.
- Factorio version: the user switches modsets. Since pack 1.4.0 the installed game is **2.0.77** (Space Exploration modpack, Space Age disabled); earlier batches were for **2.1** (Space Age planets modpack). `info.json` targets `factorio_version 2.0` / `base >= 2.0` (`update-deps.ps1` writes `base >= 2.0`). Keep following the 2.1 locale rules below. Environment: Windows, PowerShell 5.1, **no Python**.
- `terminology-uk.json` — generated en→uk glossary of names, grouped by mod → category → key. `_about.createdAt` is kept forever, `_about.updatedAt` is set on every regeneration (`tools/terms.ps1` does both).
- `translated-versions.json` — which mod version (plus hashes of its en and own-uk locale) the pack was translated against. Maintained only by `tools/check-versions.ps1`.

## ⚠ Reminders (every session that touches the pack)
- **Never commit or push on your own.** Leave changes uncommitted, show `git status` / `git diff --stat`, and wait until the user has reviewed and explicitly asks. Commit and push are separate approvals.
- **Start** with `tools/check-versions.ps1`: it lists NEW / UPDATE (en text or mod's own uk changed) / VERSION-only / REMOVED mods and a changed game version. Only UPDATE/NEW need translation work.
- **After** translating a mod, record it: `tools/check-versions.ps1 -Record @('name1','name2')` — a real PowerShell array; one comma-joined string is rejected as "Unknown mod" (or `-All` after a full pass). Don't record mods you didn't actually review.
- **After** any change to pack files, regenerate `terminology-uk.json` with `tools/terms.ps1` (updates `updatedAt`), then commit both JSON files together with the .cfg changes.

## How the pack works
- It only adds keys that have **no** `uk` translation anywhere (the mod's own `uk` **or any other mod's**, e.g. `AAI_Language_Pack` ships uk for all AAI mods), or where that `uk` equals English. Existing community translations are the base and are left alone, except for terminology/quality fixes collected in `terminology-fixes.cfg` and `terminology-fixes-ltn.cfg` (overrides of other mods' uk: official terms, Russian leftovers, broken control tokens).
- `info.json` lists every mod as a hidden optional dependency `(?) name` so the pack loads last.
- Locale files: `ukrainian-mods-translation/locale/uk/*.cfg`, grouped roughly per mod (`small-mods.cfg`, `small-mods-3..5.cfg`, `medium-mods-1..8.cfg`, `new-small-mods.cfg`, `new-small-mods-2.cfg`, `new-medium-mods-1..2.cfg`, `new-biters.cfg`, `ltn.cfg` (all LTN add-ons), `updates-1.cfg` (new keys of already-translated mods), `se-modpack-1..6.cfg` (1.4.0 SE/2.0 modpack small mods) hold several mods; `own-<mod>.cfg` are generated copies of mods' own uk (`copy-own-uk.ps1`); others are one mod each). `extra.cfg`, `rpgsystem.cfg`, `small-mods-4.cfg`, `bellicos-aegis.cfg` and `transport-drones.cfg` start with section-less keys (they must come before the first `[section]`); `extra.cfg` holds mod names.

## Keeping translations (user rule)
- **Never delete translations because a mod is missing/removed** — keep them for future use. Mod-specific keys simply stay in the pack (harmless when the mod is absent).
- Exception: keys that would override vanilla text (or a newer translation of the same key) while their mod is absent are moved, with their values, to `inactive-translations.cfg` at the repo root (not shipped; grouped by source pack file, reason on a `;` line above each key). Move them back when the mod returns.
- Questionable decisions and cross-mod conflicts go to `REVIEW.md` (repo root) for the user to review later; add new cases there instead of deciding silently.

## Hard rules (learned the hard way)
- **Factorio 2.1 rejects a `[section]` header repeated inside one file** ("Duplicate key … in property tree at ROOT"). Every section may appear once per file. Run `tools/normalize.ps1` after editing.
- No duplicate keys inside a file; avoid the same key in two files (`tools/crossdup.ps1` removes them and rebuilds the zip).
- Keep every placeholder/tag from English: `__1__`, `__ITEM__x__`, `__CONTROL__x__`, `__ALT_CONTROL__1__x__`, `[item=…]`, `[color=…]…[/color]`, `[font=…]`, `\n`. Check with `tools/tokens.ps1`.
- Ukrainian plurals: `__plural_for_parameter__1__{ends in 11,12,13,14=…|ends in 1=…|ends in 2,3,4=…|rest=…}__`.
- PowerShell 5.1: scripts containing Cyrillic **must be saved as UTF-8 with BOM** or they break. Never pass Cyrillic inside a `-command` string — write a .ps1 or use the Write tool. Write .cfg files as UTF-8 **without** BOM. Build zips with `System.IO.Compression` using forward-slash entry names (not `Compress-Archive`).
- When one mod renames another mod's key in English, the translation must follow the **later-loading** mod (check `info.json` dependencies). Resolved cases: Paracelsin overrides Accumulator-V2 / SolarMatrix / elevated-pipes; angelbob-spaceage-rebalance overrides planetaris-arig names and Muluna's console notice; planet-muluna's `copper-cable` = «Електричний дріт» wins over Angel's; angelssmelting overrides angelsrefining `loc-*` and Bob's furnace tech names; SolarMatrix wins `link-multiplier-to-cost`; Ribbonia overrides liquid_recycler / plasma_crafter names and Renai's `RTThrowerTime` description; Moshine overrides se-space-trains / minimalist-rails / snouz big accumulator & solar panel; castra-krastorio overrides Castra's battlefield science pack; k2so-cubium-compat overrides Cubium/Corrundum `*-science-pack-cubic` recipes; razi overrides Bellicos' Calidus stargate; rubia-minus-memes overrides rubia; moon-eneas overrides Construction_Drones `normal-Construction_Drone` («Кубічний друг»); LithiumBattery's `assembling-machine-4` assumed to load after moon-eneas (no dependency between them — check the load order in `%APPDATA%\Factorio\factorio-current.log` once moon-eneas is enabled). Deferred to the other mod's own uk: Maraxsis (`sp-spidertron-automation`, corpse name), Hyarion (simulating unit etc.), reskins-bobs `silicon`.

## Terminology decisions (user-approved)
- Use official Factorio uk terms first (`tools/glossary-official.txt`): маніпулятор, складальний автомат, бур, сталева балка, дослідницький пакет, опора ЛЕП, діжка, логічна мережа, розщеплення (cracking recipes), Ґлеба, Фульґора, Наувіс…
- **smelting → «виплавка»** (feminine: «Вдосконалена виплавка заліза»). Real melting/molten stays «плавлення/розплавлений».
- Enemies: кусака (masc.), плювака (fem.), черв'як; sizes Малий, Середній, Великий, Величезний, Велетенський (giant), Титанічний (titan), Гігантський (behemoth, official), …-левіафан; piercing → бронебійний. Bob's existing uk enemy names were overridden to match.
- Angel's ores: Сапфірит, Дживоліт, Стиратит, Кротиній, Рубіт, Бобмоній; crushed/chunks/crystals/purified → Подрібнений/Шматки/Кристали/Очищений; hydro-refining → гідрорафінування; slag/slurry/sludge → шлак/пульпа/шлам; geode → жеода; naphtha → лігроїн.
- Planets: Мулуна, Аріг, Харіон, Парацельсин, Мараксис, Мошайн, Коррундум, Лігнуміс, Фрозета, Секретас, Рубія, Веста, Мурія, Кубіум, Раббаска, Панглія, Ігрис, Хемія, Пелагос, Карна, Теллус, Крусібл, Кастра, Щербін, Апія/Карнова, Ріббонія, Тенебрис, Беллікос/Егіда/Калідус, Оратль, Лінокс, Енеас (moon). Mod proper names (InformaTron, Helmod, Rate Calculator) stay English.
- When English is unclear, the mod's own Russian locale (`diff-global.ps1 -Ref ru`) is a reference only — it is often wrong or a meme version; English wins.
- Batch 1.4.0 terms: official rail signals «Рейковий сигнал» / «Ланцюговий рейковий сигнал», deadlock «взаємоблокування»; Transport Drones depots «Депо пасивного/активного постачання», «Депо запиту», «Буферне депо», «Депо зберігання», «Транспортний дрон», «Дорога»; Constructron «Конструктрон»; Voidcraft void «порожнеча», voidcraft «ремесло порожнечі», rune «руна» (Вища/Піднесена), arcanology pack «таємнознавчий пакет»; SE Universe Explorer «Атлас Всесвіту», Navigation Satellite «навігаційний супутник»; factory-insight `en-fi-*`/`de-fi-*` sections are forced-language copies — never translate them.
- Batch 1.3.0 terms: технологічна картка (K2 tech card), «Ремонтна башта» (Repair_Turret, user choice — exception to турель), маглев, клацун (snapper), п'ятиніжка, official pumpjack «верстат-качалка», «Рейкотронова турель», «Модуль ощадливості», «Берегова помпа», lane splitter «Розподільник смуг», iron gear wheel «шестерня», spidertron «павукотрон», bulk/stack inserter «об'ємний/стосовий маніпулятор», thruster «прискорювач», electromagnetic plant «електромагнітна установка». Rubia (clean names): Скраптоніт, Брухтофіл, Мотлохобій, Брухтомет, сміттєроїд. Vesta: algae «водорості», fusion «термоядерний». moon-eneas: Unit-05 «Юніт-05» (masc.), Rem «Рем», repair pack renamed «Пакет інструментів».
- Official fluids: light oil → «Дизельне пальне», heavy oil → «Мазут», spoilage → «Гній»; turret → турель (not вежа/башта); spawner → лігво (not нерестовище); stack → стос; landfill → насип; crafting → виготовлення (not крафт); tile → клітинка; barrel → діжка; boiler → котел.
- Krastorio 2: steel plate → «Сталева балка» (incl. «Балка з вуглецевої сталі»); flare stack → «Факельна установка» (also Angel's).
- Ghost cursor → «курсор-привид»; Blueprint Sandboxes: sandbox → «Пісочниця», force → «Фракція».
- Space Exploration: follow SE's own uk terms (затискач, якір, доставочна гармата, Атлас Всесвіту, зона); Moon → Місяць.
- Rampant Fixed `[rampant]` name fragments are plural («Кислотні » + «кусаки: » + «Рів.3») so adjectives agree for every unit type.
- LTN: потяг (not поїзд in our text), запитувач / постачальник / депо, ідентифікатор мережі, переривання, міжповерхнева доставка, заправна станція; True/False settings → Так/Ні, default → «типово». LTN_Language_Pack uk is machine-quality: we fixed stack/blueprint/True-False errors, the rest stays.
- English identifiers the user must type (entity IDs in examples, Shortcuts-ick option tokens) stay English.
- Open question: Angel's "Smelting" train theme is still «Металургійний …» (user not asked to change yet).

## Tools (`tools/`, paths are hard-coded to this machine)
- `check-versions.ps1 [-Record names | -All]` — compare `mods/` against `translated-versions.json` / record translated state (exit code 1 = work needed).
- `diff-global.ps1 -Mods a,b | -AllNew -Out <dir> [-Ref ru]` — **preferred**: writes `<dir>\todo\<mod>.cfg` (strings with no uk anywhere: pack or any mod) and `<dir>\existing\<mod>.cfg` (`;EN english` + `key=uk` of existing translations, for terminology review). `-Ref ru` adds `;RU …` lines (mod's own ru, else any mod's) above todo keys.
- `lookup.ps1 -Pattern <regex> [-Key]` — search the official game locale (English text, or `section/key` with `-Key`) and print `section/key | en | uk`. Its console output is mangled when captured through bash; for exact uk text grep the game's `locale\uk` files directly.
- `stale.ps1 [-Detail]` — per pack file: keys / used by installed mods / dead.
- `drop-keys.ps1 -List <file>` — remove keys listed as `file.cfg|section/key` lines (used for load-order losers and orphan overrides).
- `term-check.ps1 -Dir <dir>\existing | -Pack` + `term-rules.txt` (`<en regex> => <required uk regex>`) — flag strings whose uk lacks the expected official term. Many hits are false positives (proper names, IDs, figurative use); ≈67 expected for `-Pack`.
- `diff.ps1 -Out <dir>` — older per-mod variant (only the mod's own uk counts).
- `gloss.ps1 -Out <file>` — rebuild official en→uk glossary.
- `verify.ps1` — conflicts between pack files + keys still untranslated, counting uk from any mod (depends on the installed modset; with the 1.4.0 SE modpack ≈2316: ≈2276 factory-insight `en-fi-*`/`de-fi-*` copies + ≈40 names/format-only strings).
- `tokens.ps1` — placeholder integrity (2 expected: `sp-spidertron-dock` drops a repeated `__1__`; LTN `ltn-message/stack` has more Ukrainian plural forms).
- `normalize.ps1` — merge repeated sections per file, report duplicate keys.
- `crossdup.ps1` — drop cross-file duplicate keys, drop empty sections, rebuild zip (calls `build-zip.ps1`).
- `build-zip.ps1` — package the pack as `E:\games\mods\Factorio\ukrainian-mods-translation_<info.json version>.zip`, deleting older versions of our zip. Also runs automatically from the git `pre-push` hook (`.githooks/pre-push`; enable per clone with `git config core.hooksPath .githooks`); a failed build aborts the push.
- `terms.ps1` — regenerate `terminology-uk.json`. Groups of mods that are not installed are carried over from the previous file, marked `"notInstalled": true` (never drop them).
- `copy-own-uk.ps1 [-Mods a,b]` — copy every installed mod's own uk into the pack as `own-<mod>.cfg` (user rule: keep community/official uk but copy it into our mod anyway). Skips keys our other pack files define (our translations and terminology fixes win), values equal to any mod's English (untranslated), and duplicates. Regenerates own-* of installed mods; own-* of removed mods are kept. Never edit own-* by hand — put fixes in `terminology-fixes.cfg`.
- `refs.ps1 [-Fix]` — find `__ITEM__x__`-style references in the effective uk text whose target no longer exists (Factorio: "Unknown key: item-name.x"; e.g. K2 2.x renamed items to `kr-*`, Bob's electrolysers to `bob-*`, but their uk locales kept old names). `-Fix` regenerates `ref-fixes.cfg` using the matching ref from the English string. Refs the English string also uses are upstream issues and skipped. Expect 0 after `-Fix`.
- `update-deps.ps1 [-Version x.y.z]` — add every mod in `mods/` to `info.json` dependencies (names may contain spaces, e.g. `Flow Control`), optionally set version.
- `smelt.ps1`, `enemies.ps1` — one-off helpers (smelting audit, Bob's enemy name generator).

## Typical update workflow
1. User re-extracts updated mods into `mods/` (macOS archives can leave a `__MACOSX` folder there; tools skip folders without `info.json`).
2. `tools/check-versions.ps1` → see which mods are NEW/UPDATE.
3. `tools/diff-global.ps1 -Mods <names> -Out <scratch>\new` → translate `todo\` keys into the matching pack file; run `term-check.ps1 -Dir <scratch>\new\existing` and put real fixes of existing uk into `terminology-fixes.cfg`. If a mod's own uk changed, drop pack keys it now covers (`verify.ps1` + the "overrides other mod's uk" check).
   Then `update-deps.ps1 -Version <new>` adds new mods to `info.json` as `(?) <internal name>` and bumps the version.
4. `copy-own-uk.ps1` → `refs.ps1 -Fix` → `normalize.ps1` → `verify.ps1` → `tokens.ps1` → `crossdup.ps1` (rebuilds zip) → `terms.ps1`.
5. `check-versions.ps1 -Record <the mods you did>` → confirm `check-versions.ps1` reports nothing left.
6. Make sure the version was bumped (`update-deps.ps1 -Version`; zip name follows automatically), then hand over for review. Commit/push only when the user asks.
