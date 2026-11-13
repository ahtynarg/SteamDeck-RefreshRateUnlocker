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
1. Switch to **Desktop Mode** and open **Konsole**.
2. Download the script:
   ```bash
   cd ~ && git clone https://github.com/ahtynarg/SteamDeck-RefreshRateUnlocker.git
   ```
3. Run it:
   ```bash
   ~/SteamDeck-RefreshRateUnlocker/install-RefreshRateUnlocker.sh
   ```
4. Read the warning / disclaimer and press **Yes**.
5. Select **INSTALL** and press **OK**.
6. The Steam Deck returns to Game Mode automatically.
7. Open the Quick Access menu (`...` button) → **Performance**. The refresh rate / framerate limit settings now go up to **70Hz**.

On SteamOS 3.7+ no sudo password is needed. On 3.5 / 3.6.20 the script asks for your sudo password because it changes system files.

> If you used the original script on SteamOS 3.7 / 3.8 before, you do not need to uninstall anything - this fork uses the same file name and simply overwrites it.

## Updating
```bash
cd ~/SteamDeck-RefreshRateUnlocker && git pull
```
Then run the script again and select **INSTALL**.

## How to Uninstall
Run the script again in Desktop Mode and select **UNINSTALL**:
```bash
~/SteamDeck-RefreshRateUnlocker/install-RefreshRateUnlocker.sh
```
Or, on SteamOS 3.7+, simply delete the file `~/.config/gamescope/scripts/valve.steamdeck.lcd.70Hz.lua` and return to Game Mode.

## What does this script do?
On SteamOS 3.7 and newer:
1. Checks that it runs in Desktop Mode on a Steam Deck LCD (board `Jupiter`).
2. Copies the stock gamescope display profile `/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua`.
3. Replaces the list of allowed refresh rates `40 … 60` with `40 … 70`, verifies the result and saves it as `~/.config/gamescope/scripts/valve.steamdeck.lcd.70Hz.lua`.
4. Gamescope loads user scripts after the system ones, so this profile overrides the stock one. Nothing in the read-only system partition is changed, and the file survives SteamOS updates.

Panels with their own gamescope profile (for example DeckHD) are not matched by this profile and are not affected, but use it at your own risk with replacement panels.

## Changes in this fork
1. Works on SteamOS 3.9 and newer - no hard version limit; the method is detected by the presence of the stock gamescope profile.
2. Desktop Mode detection works under Wayland (the default desktop session since SteamOS 3.8).
3. Returns to Game Mode with `steamos-session-select gamescope` (falls back to `qdbus6` / `qdbus`).
4. The refresh rate list is replaced robustly and verified - the script never reports success if the patch did not apply.
5. No sudo password needed on SteamOS 3.7+.
6. Steam Deck OLED is detected and rejected with a clear message.
7. Fixed the SteamOS 3.5 method truncating `/bin/gamescope-session`, and bundled files are found even when the script is started from another folder.

## Known Issues
1. When taking a screenshot in-game, the screen will momentarily go blank as it toggles to 60Hz, and then goes back to the custom refresh rate once the screenshot is done.

## Credits
- Original project and script: **ryanrudolf** - [GitHub](https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker), [YouTube @10MinuteSteamDeckGamer](https://www.youtube.com/@10MinuteSteamDeckGamer/). If you find this useful, please support the original author: [donation page](https://www.paypal.com/donate/?business=VSMP49KYGADT4&no_recurring=0&currency_code=CAD).
- Idea of overclocking the display panel to 70Hz: Discord user dan2wik.
- [Original video tutorial](https://youtu.be/6loG-BXmeQA) (made for an older version of the script, the steps are similar).
