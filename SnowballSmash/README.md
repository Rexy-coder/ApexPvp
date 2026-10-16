# ❄ Snowball Smash (Roblox)

Charge your push, launch a snowball down an endless mountain, steer it into snowmen,
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
| Turbo (mid-run) | **T** | TURBO button | **Y** |
| Upgrade tree | **Upgrade** button or **U** | Upgrade button | — |
| After a run | **R** retry, **Q** return | Buttons | — |

The power bar fills, then swings back down. Release at the top for **MAX POWER!**

## What's in it

* **Run:** the snowball is simulated on the client along the slope, so it rolls smoothly with no
  physics jitter. It grows as it rolls. Each smash costs speed (less when you're big),
  builds a combo (up to x5) and can roll a CRITICAL! for double coins. Boost pads add speed;
  ramps launch you over obstacles.
* **Endless mountain:** the course is generated in chunks as you roll, and the same seed is used
  on every client and the server. Obstacles get tougher (and pay more) the further down you go,
  with a Snow Fort gate every 1,500 studs and a distance sign every 500. Nobody can reach the end.
* **Every player smashes their own copy** of the course, so players never get in each other's way.
* **UI** (all built in code, see `src/client`): a chunky cartoon style like the reference video.
  Studded buttons sink when pressed and bounce on hover, wooden panels pop open with a blurred
  background, coins count up, and the hex upgrade tree pans and zooms smoothly. It all scales
  to any screen size.
* **Upgrade tree:** 22 branches and 85 upgrades (incl. Pet Power, Hatch Luck, Egg Discount, Pet Storage, Treat Collector, Turbo Time, Combo Master, Gold Rush, Distance Pay, Big Start and Turbo Power).
* **Robux shop:** 10 game passes and 12 developer products (see below), plus coin and candy skins.
* **Rebirth:** reset for +50% coins per rebirth.
* **Admin panel:** announcements, server storms, and giving coins, turbos or game passes.
* **Settings / Stats**, DataStore saving, and server-side checks on every purchase and run result.

## Update 2: "Spooky Snow" 🎃

* **🐧 Pets:** walk up to an egg in the lobby (Frosty, Glacier, Aurora and the Halloween
  Spooky Egg). Press **E** to hatch, **R** for x3 (Triple Hatch pass), or **T** for auto
  (Auto Hatch pass). There are 23 pets from Common to **Secret**, each giving +% coins, growth
  or speed. You can equip 3 (5 with the pass), and they follow you and your snowball.
  The **Pets** menu has Equip, Lock, Delete, Equip Best and Delete Unlocked.
* **📘 Index:** collect every pet in an egg for a permanent +10% coins.
* **🎃 Halloween:** pumpkins and ghost snowmen on the mountain drop **🍬 Candy**, which buys the
  Spooky Egg and the Pumpkin Ball skin. The lobby gets spooky evening lighting and glowing
  pumpkins. Switch it off after Halloween with `Config.Halloween.Enabled = false`.
* **🎁 Daily rewards:** a 7-day login streak (`Config.Daily`). **Codes** are redeemed in the
  same panel; edit them in `ServerScriptService.Codes`.
* **🏆 Leaderboards:** two global boards in the lobby (Top Distance, Top Coins Earned), updated
  every minute.
* **New Robux items:** Triple Hatch, Auto Hatch, Lucky Eggs and +2 Pet Slots passes, plus
  Legendary Pet, Bag of Candy and Cauldron of Candy products. Admins can also give candy.

## Update 3: "Winter Wonderland" 🎄 + crazy events

* **🎁 Winter:** giant presents and gingerbread houses on the mountain drop **🎁 Presents**,
  which buy the **Winter Egg** (Reindeer, Polar Bear, Gingerbread, Snow Elf, Santa Paws and the
  Secret **Frost Titan**) and the **Candy Cane Ball** (+100% coins). The lobby gets a giant
  glowing Christmas tree, presents, string lights, lamp posts and a cosy evening look.
  Switch it off after winter with `Config.Winter.Enabled = false`. Halloween is now off
  (`Config.Halloween.Enabled = false`); candy, Spooky pets and the Pumpkin Ball are kept.
* **🤯 Crazy events** (like admin abuse in Steal a Brainrot): every 30-50 minutes
  (`Config.CrazyEvents`) one starts by itself after a huge 10-second countdown on everyone's
  screen. Admins can start them any time.
  * **☄️ Meteor Shower:** red sky, meteors rain down everywhere. The ones that hit the lobby
    leave glowing shards: touch one for coins (a quarter of your best run, at least 300).
    Obstacles turn **🔥 Molten (x10)** and all coins are x1.5.
  * **🌌 Galaxy Event:** night sky full of stars and planets, low gravity in the lobby
    (super jumps!), snowballs fly 1.8x higher off ramps, **x2 hatch luck** and obstacles turn
    **🌌 Galaxy (x15)**.
  * Music for each one: `Sounds.CrazyMusic`.
* **🐾 3D pet models** (Pet Simulator style): every pet is a chunky 3D critter built from parts
  (`StarterPlayerScripts.SnowballClient.PetModels`). They hop after you, face where they walk,
  float around your snowball during a run, and Legendary/Secret pets sparkle and glow. The
  3D models also show in the inventory, Index, egg odds, admin panel and hatch screen.
* **🍬 Treat Collector** (the old Candy Collector upgrade) now boosts presents too.
* **Codes:** `WINTER` (150 presents + 2 Turbos, until 15 Jan 2027) and `METEOR` (5,000 coins).

## Update 4: more upgrades, Blizzard Egg, winter art

* **5 new upgrade branches (17 upgrades)** at the far ends of the tree: **Combo Master** (+1 max
  combo per level), **Gold Rush** (+40% loose coins), **Distance Pay** (+30% coins per stud),
  **Big Start** (+0.5 start size) and **Turbo Power** (+25% turbo speed).
* **Blizzard Egg** (5,000,000 coins, new stand in the lobby): Snow Sprite, Icicle Pup, Frost
  Mammoth, Blizzard Eagle, Snow Leopard (Legendary) and the Secret **Blizzard Wyrm**, all with 3D
  models. There are now 35 pets.
* **Art:** `docs/art/icon_winter_512.png` (game icon) and `docs/art/update_winter_wonderland.png`.

## Update 5: "Pet Paradise" 🐾

* **✨ Golden and Rainbow pets:** any pet can be a shiny one. **Golden = x2** and **Rainbow = x4**
  the pet's bonuses. Hatching has a 2% chance for Golden and 0.2% for Rainbow
  (`Pets.GoldenHatchChance` / `RainbowHatchChance`). Golden pets glow gold, Rainbow pets
  cycle through the colours, and shiny pets sparkle and have a coloured border in the menus.
* **🔧 Fusion:** fuse **3 identical unlocked pets** into 1 of the next type (Normal → Golden →
  Rainbow). Select a pet in the **Pets** menu and press **Fuse**, or press **Fuse All ✨** to fuse
  everything possible at once. Locked pets are never used. A new **Fusion Machine** stands in the
  lobby: walk up and press **F** to open the Pets menu.
* **🎉 Pet Party** (a third crazy event, in the random pool and the admin panel): confetti and a
  pink sky, **eggs cost half** and equipped pets give **+50% more** for 5 minutes.
* **Admin:** the Players tab can give any pet as Normal, Golden or Rainbow.
* **Art:** `docs/art/icon_pet_paradise_512.png` and `docs/art/update_pet_paradise.png`.

## Robux shop: put your IDs in `ReplicatedStorage.Shared.Monetization`

Create the passes and products on the Creator Dashboard (*your game → Monetization →
Passes / Developer Products*), then paste each ID over the `Id = 0` next to it.
Prices shown in the shop load from Roblox automatically. The `Price` in the file is only a fallback.
An item that still has `Id = 0` says "Coming soon" when clicked.

| Game pass | Suggested price | What it does |
|---|---|---|
| 👑 VIP | 349 R$ | `[VIP]` chat tag, 👑 VIP name tag over your head, **+25% coins** |
| 💰 2x Coins | 399 R$ | Double coins forever |
| 🎯 Perfect Push | 199 R$ | Power bar is always MAX |
| ⛄ Mega Start | 249 R$ | Start every run 2 sizes bigger |
| 🍀 Lucky Charm | 179 R$ | +10% critical chance |
| 🌈 Rainbow Ball | 149 R$ | Exclusive colour-shifting skin, +50% coins |

| Developer product | Suggested price | What it does |
|---|---|---|
| 🚀 Turbo Boost x5 | **99 R$** | 5 Turbos. Press **T** (or the TURBO button) mid-run for +90 speed and 3 s of unstoppable smashing |
| 🔥 Turbo Boost x20 | 299 R$ | 20 Turbos |
| ✨ Pile of Coins | 25 R$ | +2,500 coins |
| 💰 Bag of Coins | 99 R$ | +15,000 coins |
| 📦 Chest of Coins | 299 R$ | +60,000 coins |
| 🏦 Vault of Coins | 799 R$ | +250,000 coins |
| ⏱️ x2 Coins (15 min) | 49 R$ | Personal coin boost |
| ⌛ x2 Coins (1 hour) | 149 R$ | Personal coin boost |
| 🌪️ Server Coin Storm | 199 R$ | x2 coins for **everyone** in the server for 10 min |

**Create them all at once:** `tools/create-shop-items.ps1` (Windows PowerShell) creates every pass
and product through Roblox Open Cloud with **regional pricing and managed pricing turned off**,
then prints the IDs and saves them to `shop-ids.txt`. Instructions for the API key are at the top
of the script.

Purchases are granted by `ProcessReceipt` on the server and recorded so they are never granted twice.
Pressing TURBO with 0 turbos opens the purchase prompt.
To test perks in Studio, set `Monetization.StudioOwnsAllPasses = true`.

## Sounds and music: `ReplicatedStorage.Shared.Sounds`

* `Sounds.Music`: background music playlist, e.g. `{ "rbxassetid://123", "rbxassetid://456" }`
* `Sounds.EventMusic`: plays while a storm is running (optional)
* `Sounds.CrazyMusic`: music for the Meteor Shower / Galaxy Event (optional)
* `Sounds.UI`: Click, Hover, Open, Close, Purchase, Error, Notify, Toggle
* `Sounds.Game`: Launch, Smash, Land, Boost, Coin, Critical, MaxPower, NewBest, Mutation
* `MusicVolume`, `SfxVolume`, `UIVolume`

Use `""` to turn a sound off. The defaults are Roblox's built-in sounds; there is no music
until you add an ID.

## Admin panel: `ServerScriptService.AdminConfig`

Put your Roblox user ID in `AdminConfig.Admins`. The game's owner is always an admin, and in
Studio everyone is admin so you can test it. Admins get a 🛡️ **Admin** tile in the menu, an
`[ADMIN]` chat tag and a name tag. The panel has three tabs, and a switch at the top right
sends announcements and events to **🌍 all servers** instead of just this one:

* **🌍 Server:** announcements (filtered by Roblox), quick-message buttons, and live server
  info (players, uptime, running events, next crazy event).
* **🤯 Events:**
  * Start the **☄️ Meteor Shower** or **🌌 Galaxy Event**, turn random crazy events on or
    off, or trigger a random one right now.
  * Storms for 1/5/15/30/60 minutes: x2 / x3 Coins, **Mutation Storm** (✨Golden x3 /
    💎Diamond x8), Mega Growth, Blizzard Speed and Lucky Storm. Stop everything with one button.
* **👥 Players:** pick anyone from the list (with their avatar) to see their coins, candy,
  presents, turbos, pets and rebirths, then:
  * give or take coins, turbos, candy or presents;
  * give any pet (tap it);
  * give or remove any game pass (saved);
  * **Bring**, **Go to** or **Kick** (kick asks twice; admins can't be kicked).

Every admin action is checked on the server, so non-admins can't use the remote.

## Tweaking

* **Gameplay balance** (`ReplicatedStorage.Shared.Config`): launch speed, friction, growth,
  upgrade costs and effects, skins, rebirth, turbo strength, storm definitions and mutation odds.
* **The course** (`ReplicatedStorage.Shared.CourseGen`): slope angle and width, how fast
  obstacles get tougher (`ToughScale`) and richer (`CoinScale`), gate spacing, and which obstacles
  appear at which distance. The obstacle models are built in `SnowballClient.CourseBuilder`.
* **The lobby** (`Workspace.Lobby`) is normal parts you can edit in Studio.
  `Workspace.Course.Preview` only shows the start of the slope in the editor and is removed when
  the game runs.

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
| `src/shared/*.luau` | `ReplicatedStorage.Shared.*` (Config, Monetization, Sounds, CourseGen) |
| `src/server/GameServer.server.luau` | `ServerScriptService.GameServer` |
| `src/server/AdminConfig.luau` | `ServerScriptService.AdminConfig` |
| `src/client/Main.client.luau` | `StarterPlayerScripts.SnowballClient` (LocalScript) |
| `src/client/*.luau` (the rest) | ModuleScripts inside `SnowballClient` |
