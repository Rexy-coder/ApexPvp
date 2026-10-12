# ❄ Snowball Smash (Roblox)

Charge your push, launch a snowball down a giant mountain, steer it into snowmen,
trees, ice walls and log cabins, and watch it **grow bigger with every stud it rolls**.
Bigger snowball = harder smashes, more coins and longer combos. Spend the coins in a hexagon
upgrade tree, unlock new ball skins, then rebirth for a permanent coin bonus.

## Open it

1. Open **`SnowballSmash.rbxl`** in Roblox Studio (File → Open from File).
   `SnowballSmash.rbxlx` is the same place in XML format.
2. Press **Play**.
3. To save progress between sessions, publish the place and turn on
   *Game Settings → Security → Enable Studio Access to API Services*.
   Without it the game still runs, it just starts fresh every time.

## How to play

| Action | Keyboard / mouse | Touch | Gamepad |
|---|---|---|---|
| Start a run | **Roll!** button, **E**, or walk onto the blue pad | Roll! button | — |
| Charge power | Hold **click** or **Space**, release to launch | Hold anywhere | Hold **A** |
| Steer | **A / D** or arrow keys | Touch left / right half | Left stick |
| Upgrade tree | **Upgrade** button or **U** | Upgrade button | — |
| After a run | **R** retry, **Q** return | Buttons | — |

The power bar fills, then swings back down. Release at the top for **MAX POWER!**

## What's in it

* **Run:** the snowball is simulated on the client along the slope, so it rolls smoothly with no
  physics jitter. It grows as it rolls. Each smash costs speed (less when you're big),
  builds a combo (up to x5) and can roll a CRITICAL! for double coins. Boost pads add speed;
  ramps launch you over obstacles. The run ends when you stop or hit the Snow Fort at the bottom.
* **Every player smashes their own copy** of the course, so players never get in each other's way.
* **UI** (all built in code, see `src/client`): a chunky cartoon style like the reference video.
  Studded buttons sink when pressed and bounce on hover, wooden panels pop open with a blurred
  background, coins count up, and the hex upgrade tree pans and zooms smoothly. It all scales
  to any screen size.
* **Upgrade tree:** 11 branches and 45 upgrades: Push Power, Snow Pack, Smash Power,
  Coin Bonus, Combo Time, Carving, Slick Wax, Mega Ball, Lucky Flake, Turbo Pads and Big Air.
* **Shop:** 6 snowball skins, each with a coin bonus. **Rebirth:** reset for +50% coins per rebirth.
* **Settings:** Music, SFX, Camera Shake, Speed Lines, Hints (saved per player).
* **Stats:** runs, best score / distance / combo, total smashed, rebirths.
* **Server:** DataStore saving, server-side purchases, and run results checked against
  what the course could actually pay out.

## Tweaking

Everything you'd want to balance lives in `ReplicatedStorage.Shared.Config`
(`src/shared/Config.luau`): launch speed, friction, growth, upgrade costs and effects, skins,
rebirth price, and sounds. Background music is off by default. Set `Config.Sounds.Music` to an
audio asset id you own (e.g. `"rbxassetid://123"`) to add some.

You can also edit the map directly in Studio. Anything inside `Workspace.Course.Smashables`
becomes smashable. Give it the attributes `Toughness` (number) and `Coins` (number).
Parts in `Workspace.Course.Pads` with a `PadType` attribute of `Boost` or `Ramp` work as pads.

## Rebuilding from source

The place file is generated from the scripts in `src/` and the map builder in `build/build.luau`.
You need [Lune](https://github.com/lune-org/lune):

```sh
cd SnowballSmash
lune run build/build.luau .
```

This rewrites `SnowballSmash.rbxl` and `SnowballSmash.rbxlx`.

| File | Goes to |
|---|---|
| `src/shared/Config.luau` | `ReplicatedStorage.Shared.Config` |
| `src/server/GameServer.server.luau` | `ServerScriptService.GameServer` |
| `src/client/Main.client.luau` | `StarterPlayerScripts.SnowballClient` (LocalScript) |
| `src/client/*.luau` (the rest) | ModuleScripts inside `SnowballClient` |
