# SteamDeck Refresh Rate Unlocker (SteamOS 3.9+ fork)

Unlock the original **Steam Deck LCD** display to use up to **70Hz** refresh rate (do not confuse this with FPS).

This is a fork of [ryanrudolfoba/SteamDeck-RefreshRateUnlocker](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker), updated to work on current SteamOS releases (**3.7, 3.8, 3.9 and newer**). The original script stops with *"This is unsupported version"* on SteamOS 3.9 - this fork fixes that.

All credit for the original idea and script goes to **ryanrudolf** ([@10MinuteSteamDeckGamer](https://www.youtube.com/@10MinuteSteamDeckGamer/)) and to Discord user dan2wik for the idea of overclocking the panel to 70Hz. See [Credits](#credits).

## Disclaimer
1. Do this at your own risk!
2. This is for educational and research purposes only!
3. Only for the **Steam Deck LCD** (model with the original LCD panel). The script refuses to run on the Steam Deck OLED.

## Compatibility

| SteamOS | Method | Status |
|---|---|---|
| 3.7, 3.8, 3.9 and newer | gamescope display profile in `~/.config/gamescope/scripts` | Supported |
| 3.6.20 | patched gamescope binary (from the original project) | Supported |
| 3.5.x | edit `/bin/gamescope-session` (from the original project) | Supported |
| anything else | - | Not supported |

For SteamOS 3.7 and newer there is **no version number check**: the mod is installed whenever SteamOS ships the stock Steam Deck LCD gamescope profile, so future SteamOS updates should keep working without a script update.

## Installation

### Option 1 - one click, no terminal (recommended)
1. Switch to **Desktop Mode**.
2. Download **[RefreshRateUnlocker.desktop](https://github.com/ahtynarg/SteamDeck-RefreshRateUnlocker/releases/latest/download/RefreshRateUnlocker.desktop)** (from the [latest release](https://github.com/ahtynarg/SteamDeck-RefreshRateUnlocker/releases/latest)) and move it from *Downloads* to the **Desktop**.
3. Double-click **Refresh Rate Unlocker (70Hz)** on the Desktop. If KDE asks whether to run / trust the file, allow it.
4. A Konsole window opens, downloads (or updates) this project into `~/SteamDeck-RefreshRateUnlocker` and starts the installer.
5. Read the warning / disclaimer and press **Yes**, then select **INSTALL** and press **OK**.
6. The Steam Deck returns to Game Mode automatically.
7. Open the Quick Access menu (`...` button) → **Performance**. The refresh rate / framerate limit settings now go up to **70Hz**.

Keep the shortcut on the Desktop - double-click it again any time to **update**, re-install or **UNINSTALL** the mod.
If an older copy of the original project already exists in `~/SteamDeck-RefreshRateUnlocker`, it is not deleted, just renamed to `~/SteamDeck-RefreshRateUnlocker.backup-<date>`.

### Option 2 - terminal
1. Switch to **Desktop Mode** and open **Konsole**.
2. Run (does the same as the shortcut - downloads or updates the project and starts the installer):
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/ahtynarg/SteamDeck-RefreshRateUnlocker/main/bootstrap.sh)
   ```
3. Continue from step 5 of Option 1.

**sudo password:** on SteamOS 3.7+ no password is needed at all. On 3.5 / 3.6.20 the script changes system files and handles the password the same way as the Decky Loader installer:
- if you already have a sudo password, it asks for it in a dialog;
- if you have no password, it sets a random temporary one and removes it again when the script finishes (also when you cancel).

> If you used the original script on SteamOS 3.7 / 3.8 before, you do not need to uninstall anything - this fork uses the same file name and simply overwrites it.

## Updating
Double-click the **Refresh Rate Unlocker (70Hz)** shortcut - it updates the project automatically before starting. Or in a terminal:
```bash
cd ~/SteamDeck-RefreshRateUnlocker && git pull
```
Then select **INSTALL** again.

## How to Uninstall
Double-click the **Refresh Rate Unlocker (70Hz)** shortcut in Desktop Mode (or run the script) and select **UNINSTALL**:
```bash
~/SteamDeck-RefreshRateUnlocker/install-RefreshRateUnlocker.sh
```
Or, on SteamOS 3.7+, simply delete the file `~/.config/gamescope/scripts/valve.steamdeck.lcd.70Hz.lua` and return to Game Mode.

## What does this script do?
On SteamOS 3.7 and newer:
1. Checks that it runs in Desktop Mode on a Steam Deck LCD (board `Jupiter`) and that SteamOS ships the stock gamescope Steam Deck LCD profile (`/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua`).
2. Writes a small gamescope script `~/.config/gamescope/scripts/valve.steamdeck.lcd.70Hz.lua` that only changes the list of allowed refresh rates of that stock profile from `40 … 60` to `40 … 70`.
3. Gamescope runs user scripts after its own display profiles, so everything else (colorimetry, mode timings, panel detection) stays exactly as shipped with SteamOS, including future fixes from Valve. Nothing in the read-only system partition is changed, and the file survives SteamOS updates.

Panels with their own gamescope profile (for example DeckHD) are not affected, but use the mod at your own risk with replacement panels.

## Changes in this fork
1. Works on SteamOS 3.9 and newer - no hard version limit; the method is detected by the presence of the stock gamescope profile.
2. On SteamOS 3.7+ only the refresh rate list of the stock profile is overridden, instead of copying the whole profile - Valve's updates to the rest of the profile keep working.
3. One-click `.desktop` launcher that downloads / updates the project and starts the installer.
4. Desktop Mode detection works under Wayland (the default desktop session since SteamOS 3.8).
5. Returns to Game Mode with `steamos-session-select gamescope` (falls back to `qdbus6` / `qdbus`).
6. Every step is checked - the script never reports success if a file could not be written or removed.
7. No sudo password needed on SteamOS 3.7+; on 3.5 / 3.6.20 a temporary password is set and removed automatically if you have none (like the Decky installer). Passwords with special characters work, and sudo rights are not left cached.
8. SteamOS 3.6.20: the installed and bundled gamescope binaries are checked before anything is replaced.
9. Steam Deck OLED is detected and rejected with a clear message.
10. Automated tests (GitHub Actions) run on every change and weekly against the latest gamescope profile.

## Known Issues
1. When taking a screenshot in-game, the screen will momentarily go blank as it toggles to 60Hz, and then goes back to the custom refresh rate once the screenshot is done.

## Credits
- Original project and script: **ryanrudolf** - [GitHub](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker), [YouTube @10MinuteSteamDeckGamer](https://www.youtube.com/@10MinuteSteamDeckGamer/). If you find this useful, please support the original author: [donation page](https://www.paypal.com/donate/?business=VSMP49KYGADT4&no_recurring=0&currency_code=CAD).
- Idea of overclocking the display panel to 70Hz: Discord user dan2wik.
- [Original video tutorial](https://youtu.be/6loG-BXmeQA) (made for an older version of the script, the steps are similar).
