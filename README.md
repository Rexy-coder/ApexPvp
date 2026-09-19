# ApexPvP Client

Standalone launcher for a fast, PvP-focused **Minecraft Java 1.21.11 (Fabric)** setup:
optimisation mods, keystrokes / CPS / armor HUD, **short swords, low fire, low shield**,
**Microsoft login inside the launcher**, and a music player with an in-game "now playing" pill at the top centre.

## Start
* **Windows (easiest): double-click `ApexPvP.exe`.** The first start unpacks the launcher and, if the PC has no
  Python, installs a private copy (no admin rights, ~3-5 min, needs internet). Later starts take a second.
  Windows SmartScreen may warn about an unknown publisher (the exe is not code-signed): *More info -> Run anyway*.
* Without the exe: install Python 3.11+ (tick "Add to PATH"), double-click `run.bat`. Linux/macOS: `./run.sh`.
* True single-file build with Python bundled inside: run `build_exe.bat` on a Windows PC (uses PyInstaller).

First **PLAY** downloads Minecraft, Java, Fabric and the mods (a few minutes, needs internet). After that it starts fast.

## Microsoft login (one-time setup, ~5 minutes)
Microsoft only lets a launcher sign in with its own registered app. It is free:
1. On the Play page click **Sign in with Microsoft** (or Settings -> *Sign in*). The launcher walks you through it.
2. Azure portal -> *App registrations* -> *New registration* -> supported accounts: **"Personal Microsoft accounts only"**
   (or "any tenant + personal"). Under *Authentication* set **Allow public client flows = Yes**.
3. Copy the **Application (client) ID** into the launcher.
4. Ask Mojang to approve that ID once: https://aka.ms/mce-reviewappid (can take a few days).
5. Click *Sign in*, the launcher shows a short code, approve it at microsoft.com/link (any device). Done - the launcher
   keeps you signed in and refreshes the session by itself.

Until Mojang has approved the ID, the launcher tells you so and you can keep using an offline username.

## Music
* Put mp3 / ogg / wav / flac files in the music folder (Music tab -> *Open*). When started through
  `ApexPvP.exe` the folder is `Music\ApexPvP` in your user folder; otherwise it is `music/` next to the launcher.
* The title/artist pill shows in the launcher and, while Minecraft has focus, **at the top centre of the game window**
  (with the clock, like the video). It is a separate click-through window, no game mod needed. Switch it off in
  Music -> *Music pill in game*.
* Hotkeys work while Minecraft has focus: Ctrl+Alt+Right (next), Ctrl+Alt+Left (previous), Ctrl+Alt+Space (pause).

## What you get
| Feature | How it works |
|---|---|
| Look | Pixel-art sunset wallpaper, lock-screen clock ("Click to unlock"), round glass icon dock, frosted pages. The same sunset is used as the Minecraft title-screen panorama (Pack tab) |
| Optimisation | Sodium, Lithium, FerriteCore, Entity Culling, ImmediatelyFast, ModernFix from Modrinth + tuned JVM flags + fast defaults in a fresh `options.txt` |
| HUD | Sodium Extra (FPS/coords) + keystrokes / CPS / armor / mob-health HUD mods picked from Modrinth for 1.21.11. See the **Mods** tab for what was installed; toggle any off |
| Short swords / low shield / low fire | A resource pack (`ApexPvP`) generated from your own game files. Tune sizes on the **Pack** tab, press *Save & rebuild* |
| Music | See above |
| Accounts | Microsoft (device-code login) or an offline username |

## Files
Game data lives in `%APPDATA%\ApexPvP` (Windows) / `~/.local/share/ApexPvP` (Linux). `game\mods` holds the mods; drop your own extra `.jar` files there and they are left alone.
Logs: `logs\game.log`. The exe's unpack/setup log: `%LOCALAPPDATA%\ApexPvP\setup.log`.

## Notes
* The lock screen and dock are the **launcher's** screen. The title-screen look inside Minecraft comes from the
  resource pack panorama (a client mod would be needed for a fully custom in-game menu).
* Mods that have no 1.21.11 build yet are skipped and listed in the log.
* Cheat-style mods (x-ray, aimbot, autoclick, hitbox, reach...) are never auto-installed.
* Not affiliated with Mojang or Microsoft.
