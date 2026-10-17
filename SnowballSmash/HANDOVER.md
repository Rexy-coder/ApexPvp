# Snowball Smash - handover

Roblox game, built entirely from Luau source into `SnowballSmash.rbxl` with Lune.
Branch: `claude/roblox-game-design-zit1io`. Read `README.md` for the full feature list.

## Rebuild / check
- Build: `lune run build/build.luau .` (writes `SnowballSmash.rbxl` and `.rbxlx`; Lune 0.8.9)
- Type check: `luau-lsp analyze --definitions=<defs for luau-lsp 1.32> --sourcemap=sourcemap.json src/`
- All scripts use `--!nonstrict`. New client modules must be added to `build/build.luau`
  (the module list near the bottom) and to `sourcemap.json`.

## Layout
- `src/shared/` Config (upgrades, skins, events, currencies, winter/halloween), Monetization
  (pass/product IDs), Sounds, CourseGen (endless seeded course), Pets (eggs + 35 pets)
- `src/server/` GameServer (data, purchases, admin, crazy events), AdminConfig, Codes
- `src/client/` Main (wiring), Hud, Panels (shop + admin panel), UpgradeTree, Runner,
  CourseBuilder, PetsUI, PetModels (3D pets), CrazyFX, DailyUI, Effects, UIKit
- `build/` build.luau (map + scripts), make_*.py (art), `tools/` PowerShell shop scripts

## What exists
- Core: charge a power bar, roll a snowball down an endless mountain, smash things for coins,
  hex upgrade tree (22 branches / 85 upgrades), skins, rebirth, turbo boosts.
- Update 2 (Halloween): pets, eggs, Index, candy, daily rewards, codes, leaderboards.
- Update 3: Winter event (presents, Winter Egg, Candy Cane Ball, lobby decorations), crazy events
  (Meteor Shower, Galaxy Event, random every 30-50 min with a 10 s countdown), rebuilt admin panel
  (Server / Events / Players tabs, optional all-servers mode), 3D pet models.
- Config switches: `Config.Halloween.Enabled` (now false), `Config.Winter.Enabled` (true),
  `Config.CrazyEvents.Auto`.

## Shop (all 22 IDs filled in `Monetization.luau`)
10 game passes + 12 developer products. `tools/setup-shop.ps1` creates missing items and
uploads icons (needs an Open Cloud API key; never share it). Universe ID 10770520658.

## Things the owner still has to do / know
- Put real music IDs in `Sounds.luau` (`rbxassetid://...`; temp `rbxtemp` IDs don't work).
- Put admin user IDs in `ServerScriptService.AdminConfig` (the creator is always admin).
- Publishing the .rbxl overwrites scripts in the live game: copy custom Sounds/AdminConfig/Codes first.
- Nothing has been tested inside Roblox Studio yet (only type-checked and built outside it).
  First job for a Studio-connected session: play-test everything, especially the crazy events,
  3D pets (PetModels), the admin panel and the hatch screen.

- Update 4: 5 more upgrade branches, Blizzard Egg (6 pets with 3D models), winter icon +
  update picture in `docs/art/` (`icon_winter_512.png`, `update_winter_wonderland.png`).

- Update 5 (Pet Paradise): Golden/Rainbow pet variants (`V` field on each owned pet), fusion
  (PetAction `Fuse` / `FuseAll`), Fusion Machine in the lobby, Pet Party crazy event, shiny
  hatches, admin can give shiny pets. Art in `docs/art/*pet_paradise*`.
  The pet preview renders used for the art come from a small ray tracer (not in the repo).

- Update 6: 3 more crazy events (Blizzard, GoldFrenzy, Thunder; weather + lightning in
  `CrazyFX`), custom multiplier storms (CoinsX / LuckX / PetsX, the multiplier lives in the
  `EventMult_<id>` GameState attribute), winter thumbnail `docs/art/thumbnail_winter_1920x1080.png`.
  Winter + Pet Paradise + these events ship together as "the Winter Update".

## Ideas not built yet
Nothing planned. Ask the owner what they want next.
