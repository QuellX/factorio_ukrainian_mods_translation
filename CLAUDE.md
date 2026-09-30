# Ukrainian translation pack for the user's Factorio mods

This folder (`E:\games\mods\locale`) is a git repo (remote `git@github.com:QuellX/factorio_ukrainian_mods_translation.git`) holding the translation mod we build. **Unpacked copies** of the user's Factorio mods (one folder each, read-only reference, plus `mod-list.json`/`mod-settings.dat`) live in `mods/`, which is git-ignored — never commit third-party mod files.

- Our mod: `ukrainian-mods-translation/` (source). Packaged zip goes to the real mods folder: `E:\games\mods\Factorio\ukrainian-mods-translation_<version>.zip` (current 1.1.0; delete the previous version's zip there when bumping).
- Official game locale (terminology source of truth): `E:\games\steam\steamapps\common\Factorio\data\{base,space-age,quality,elevated-rails,recycler,core}\locale\{en,uk}\*.cfg`.
- Factorio version: **2.1**. Environment: Windows, PowerShell 5.1, **no Python**.
- `terminology-uk.json` — generated en→uk glossary of names, grouped by mod → category → key. `_about.createdAt` is kept forever, `_about.updatedAt` is set on every regeneration (`tools/terms.ps1` does both).
- `translated-versions.json` — which mod version (plus hashes of its en and own-uk locale) the pack was translated against. Maintained only by `tools/check-versions.ps1`.

## ⚠ Reminders (every session that touches the pack)
- **Never commit or push on your own.** Leave changes uncommitted, show `git status` / `git diff --stat`, and wait until the user has reviewed and explicitly asks. Commit and push are separate approvals.
- **Start** with `tools/check-versions.ps1`: it lists NEW / UPDATE (en text or mod's own uk changed) / VERSION-only / REMOVED mods and a changed game version. Only UPDATE/NEW need translation work.
- **After** translating a mod, record it: `tools/check-versions.ps1 -Record <internal-name>[,<name>…]` (or `-All` after a full pass). Don't record mods you didn't actually review.
- **After** any change to pack files, regenerate `terminology-uk.json` with `tools/terms.ps1` (updates `updatedAt`), then commit both JSON files together with the .cfg changes.

## How the pack works
- It only adds keys that have **no** `uk` translation anywhere (the mod's own `uk` **or any other mod's**, e.g. `AAI_Language_Pack` ships uk for all AAI mods), or where that `uk` equals English. Existing community translations are the base and are left alone, except for terminology/quality fixes collected in `terminology-fixes.cfg` (overrides of other mods' uk: official terms, Russian leftovers, broken control tokens).
- `info.json` lists every mod as a hidden optional dependency `(?) name` so the pack loads last.
- Locale files: `ukrainian-mods-translation/locale/uk/*.cfg`, grouped roughly per mod (`small-mods.cfg`, `medium-mods-1..3.cfg`, `new-small-mods.cfg`, `new-medium-mods-1..2.cfg`, `new-biters.cfg` hold several mods; others are one mod each). `extra.cfg` starts with a section-less key and holds mod names.

## Hard rules (learned the hard way)
- **Factorio 2.1 rejects a `[section]` header repeated inside one file** ("Duplicate key … in property tree at ROOT"). Every section may appear once per file. Run `tools/normalize.ps1` after editing.
- No duplicate keys inside a file; avoid the same key in two files (`tools/crossdup.ps1` removes them and rebuilds the zip).
- Keep every placeholder/tag from English: `__1__`, `__ITEM__x__`, `__CONTROL__x__`, `__ALT_CONTROL__1__x__`, `[item=…]`, `[color=…]…[/color]`, `[font=…]`, `\n`. Check with `tools/tokens.ps1`.
- Ukrainian plurals: `__plural_for_parameter__1__{ends in 11,12,13,14=…|ends in 1=…|ends in 2,3,4=…|rest=…}__`.
- PowerShell 5.1: scripts containing Cyrillic **must be saved as UTF-8 with BOM** or they break. Never pass Cyrillic inside a `-command` string — write a .ps1 or use the Write tool. Write .cfg files as UTF-8 **without** BOM. Build zips with `System.IO.Compression` using forward-slash entry names (not `Compress-Archive`).
- When one mod renames another mod's key in English, the translation must follow the **later-loading** mod (check `info.json` dependencies). Resolved cases: Paracelsin overrides Accumulator-V2 / SolarMatrix / elevated-pipes; angelbob-spaceage-rebalance overrides planetaris-arig names and Muluna's console notice; planet-muluna's `copper-cable` = «Електричний дріт» wins over Angel's; angelssmelting overrides angelsrefining `loc-*` and Bob's furnace tech names; SolarMatrix wins `link-multiplier-to-cost`. Deferred to the other mod's own uk: Maraxsis (`sp-spidertron-automation`, corpse name), Hyarion (simulating unit etc.), reskins-bobs `silicon`.

## Terminology decisions (user-approved)
- Use official Factorio uk terms first (`tools/glossary-official.txt`): маніпулятор, складальний автомат, бур, сталева балка, дослідницький пакет, опора ЛЕП, діжка, логічна мережа, розщеплення (cracking recipes), Ґлеба, Фульґора, Наувіс…
- **smelting → «виплавка»** (feminine: «Вдосконалена виплавка заліза»). Real melting/molten stays «плавлення/розплавлений».
- Enemies: кусака (masc.), плювака (fem.), черв'як; sizes Малий, Середній, Великий, Величезний, Велетенський (giant), Титанічний (titan), Гігантський (behemoth, official), …-левіафан; piercing → бронебійний. Bob's existing uk enemy names were overridden to match.
- Angel's ores: Сапфірит, Дживоліт, Стиратит, Кротиній, Рубіт, Бобмоній; crushed/chunks/crystals/purified → Подрібнений/Шматки/Кристали/Очищений; hydro-refining → гідрорафінування; slag/slurry/sludge → шлак/пульпа/шлам; geode → жеода; naphtha → лігроїн.
- Planets: Мулуна, Аріг, Харіон, Парацельсин, Мараксис. Mod proper names (InformaTron, Helmod, Rate Calculator) stay English.
- Official fluids: light oil → «Дизельне пальне», heavy oil → «Мазут», spoilage → «Гній»; turret → турель (not вежа/башта); spawner → лігво (not нерестовище); stack → стос; landfill → насип; crafting → виготовлення (not крафт); tile → клітинка; barrel → діжка; boiler → котел.
- Krastorio 2: steel plate → «Сталева балка» (incl. «Балка з вуглецевої сталі»); flare stack → «Факельна установка» (also Angel's).
- Ghost cursor → «курсор-привид»; Blueprint Sandboxes: sandbox → «Пісочниця», force → «Фракція».
- Space Exploration: follow SE's own uk terms (затискач, якір, доставочна гармата, Атлас Всесвіту, зона); Moon → Місяць.
- Rampant Fixed `[rampant]` name fragments are plural («Кислотні » + «кусаки: » + «Рів.3») so adjectives agree for every unit type.
- English identifiers the user must type (entity IDs in examples, Shortcuts-ick option tokens) stay English.
- Open question: Angel's "Smelting" train theme is still «Металургійний …» (user not asked to change yet).

## Tools (`tools/`, paths are hard-coded to this machine)
- `check-versions.ps1 [-Record names | -All]` — compare `mods/` against `translated-versions.json` / record translated state (exit code 1 = work needed).
- `diff-global.ps1 -Mods a,b | -AllNew -Out <dir>` — **preferred**: writes `<dir>\todo\<mod>.cfg` (strings with no uk anywhere: pack or any mod) and `<dir>\existing\<mod>.cfg` (`;EN english` + `key=uk` of existing translations, for terminology review).
- `term-check.ps1 -Dir <dir>\existing | -Pack` + `term-rules.txt` (`<en regex> => <required uk regex>`) — flag strings whose uk lacks the expected official term. Many hits are false positives (proper names, IDs, figurative use); ≈67 expected for `-Pack`.
- `diff.ps1 -Out <dir>` — older per-mod variant (only the mod's own uk counts).
- `gloss.ps1 -Out <file>` — rebuild official en→uk glossary.
- `verify.ps1` — conflicts between pack files + keys still untranslated, counting uk from any mod (≈41 expected: names, placeholders, intentional deferrals).
- `tokens.ps1` — placeholder integrity (1 expected: `sp-spidertron-dock` drops a repeated `__1__`).
- `normalize.ps1` — merge repeated sections per file, report duplicate keys.
- `crossdup.ps1` — drop cross-file duplicate keys, drop empty sections, rebuild zip (calls `build-zip.ps1`).
- `build-zip.ps1` — package the pack as `E:\games\mods\Factorio\ukrainian-mods-translation_<info.json version>.zip`, deleting older versions of our zip. Also runs automatically from the git `pre-push` hook (`.githooks/pre-push`; enable per clone with `git config core.hooksPath .githooks`); a failed build aborts the push.
- `terms.ps1` — regenerate `terminology-uk.json`.
- `smelt.ps1`, `enemies.ps1` — one-off helpers (smelting audit, Bob's enemy name generator).

## Typical update workflow
1. User re-extracts updated mods into `mods/`.
2. `tools/check-versions.ps1` → see which mods are NEW/UPDATE.
3. `tools/diff-global.ps1 -Mods <names> -Out <scratch>\new` → translate `todo\` keys into the matching pack file; run `term-check.ps1 -Dir <scratch>\new\existing` and put real fixes of existing uk into `terminology-fixes.cfg`. If a mod's own uk changed, drop pack keys it now covers (`verify.ps1` + the "overrides other mod's uk" check).
   Also add new mods to `info.json` dependencies as `(?) <internal name>`.
4. `normalize.ps1` → `verify.ps1` → `tokens.ps1` → `crossdup.ps1` (rebuilds zip) → `terms.ps1`.
5. `check-versions.ps1 -Record <the mods you did>` → confirm `check-versions.ps1` reports nothing left.
6. Bump `version` in `ukrainian-mods-translation/info.json` (zip name follows automatically), then hand over for review. Commit/push only when the user asks.
