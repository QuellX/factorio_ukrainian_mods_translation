# Ukrainian translation pack for the user's Factorio mods

This folder (`E:\games\mods\locale`) is a git repo (remote `git@github.com:QuellX/factorio_ukrainian_mods_translation.git`) holding the translation mod we build. **Unpacked copies** of the user's Factorio mods (one folder each, read-only reference, plus `mod-list.json`/`mod-settings.dat`) live in `mods/`, which is git-ignored — never commit third-party mod files.

- Our mod: `ukrainian-mods-translation/` (source). Packaged zip goes to the real mods folder: `E:\games\mods\Factorio\ukrainian-mods-translation_1.0.0.zip`.
- Official game locale (terminology source of truth): `E:\games\steam\steamapps\common\Factorio\data\{base,space-age,quality,elevated-rails,recycler,core}\locale\{en,uk}\*.cfg`.
- Factorio version: **2.1**. Environment: Windows, PowerShell 5.1, **no Python**.
- `terminology-uk.json` — generated en→uk glossary of names, grouped by mod → category → key. `_about.createdAt` is kept forever, `_about.updatedAt` is set on every regeneration (`tools/terms.ps1` does both).
- `translated-versions.json` — which mod version (plus hashes of its en and own-uk locale) the pack was translated against. Maintained only by `tools/check-versions.ps1`.

## ⚠ Reminders (every session that touches the pack)
- **Start** with `tools/check-versions.ps1`: it lists NEW / UPDATE (en text or mod's own uk changed) / VERSION-only / REMOVED mods and a changed game version. Only UPDATE/NEW need translation work.
- **After** translating a mod, record it: `tools/check-versions.ps1 -Record <internal-name>[,<name>…]` (or `-All` after a full pass). Don't record mods you didn't actually review.
- **After** any change to pack files, regenerate `terminology-uk.json` with `tools/terms.ps1` (updates `updatedAt`), then commit both JSON files together with the .cfg changes.

## How the pack works
- It only adds keys a mod has **not** already translated to `uk` (or where the mod's `uk` equals English). Existing community translations are left alone, with deliberate exceptions listed below.
- `info.json` lists every mod as a hidden optional dependency `(?) name` so the pack loads last.
- Locale files: `ukrainian-mods-translation/locale/uk/*.cfg`, grouped roughly per mod (`small-mods.cfg`, `medium-mods-1..3.cfg` hold several small mods; others are one mod each). `extra.cfg` starts with a section-less key and holds mod names.

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
- Open question: Angel's "Smelting" train theme is still «Металургійний …» (user not asked to change yet).

## Tools (`tools/`, paths are hard-coded to this machine)
- `check-versions.ps1 [-Record names | -All]` — compare `mods/` against `translated-versions.json` / record translated state (exit code 1 = work needed).
- `diff.ps1 -Out <dir>` — per mod, dump en keys missing from its uk into `<dir>\<mod>.cfg` (start here after mod updates).
- `gloss.ps1 -Out <file>` — rebuild official en→uk glossary.
- `verify.ps1` — conflicts between pack files + keys still untranslated (≈47 expected: names, placeholders, intentional deferrals).
- `tokens.ps1` — placeholder integrity (1 expected: `sp-spidertron-dock` drops a repeated `__1__`).
- `normalize.ps1` — merge repeated sections per file, report duplicate keys.
- `crossdup.ps1` — drop cross-file duplicate keys, drop empty sections, rebuild zip.
- `terms.ps1` — regenerate `terminology-uk.json`.
- `smelt.ps1`, `enemies.ps1` — one-off helpers (smelting audit, Bob's enemy name generator).

## Typical update workflow
1. User re-extracts updated mods into `mods/`.
2. `tools/check-versions.ps1` → see which mods are NEW/UPDATE.
3. `tools/diff.ps1 -Out <scratch>\todo` → translate new keys of those mods into the matching pack file. If a mod's own uk changed, drop pack keys it now covers (`verify.ps1` + the "overrides other mod's uk" check).
4. `normalize.ps1` → `verify.ps1` → `tokens.ps1` → `crossdup.ps1` (rebuilds zip) → `terms.ps1`.
5. `check-versions.ps1 -Record <the mods you did>` → confirm `check-versions.ps1` reports nothing left.
6. Bump `version` in `ukrainian-mods-translation/info.json` (and zip name in `crossdup.ps1`), commit, push.
