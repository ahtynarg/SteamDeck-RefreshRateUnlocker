#!/bin/bash
# End-to-end tests for install-RefreshRateUnlocker.sh with a faked Steam Deck environment.
# Uses the latest Steam Deck LCD profile from upstream gamescope, so this also detects
# when Valve changes the profile format in a way that breaks the mod.
#
# Usage: tests/run-tests.sh [path/to/valve.steamdeck.lcd.lua]

set -u
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAILED=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=1; }

# stock gamescope profile
if [ $# -ge 1 ]
then
	cp "$1" "$WORK/lcd.lua"
else
	curl -fsSL https://raw.githubusercontent.com/ValveSoftware/gamescope/master/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua -o "$WORK/lcd.lua" || { echo "Could not download the gamescope profile"; exit 1; }
fi

# stubs for the Steam Deck tools
mkdir -p "$WORK/bin" "$WORK/home"
cat > "$WORK/bin/zenity" <<'EOF'
#!/bin/bash
[[ "$*" == *--list* ]] && echo "$ZENITY_CHOICE"
exit 0
EOF
printf '#!/bin/bash\necho "[stub] steamos-session-select $*"\n' > "$WORK/bin/steamos-session-select"
printf '#!/bin/bash\n' > "$WORK/bin/sleep"
chmod +x "$WORK/bin/"*

# installer copy that reads the fake board name, os-release and profile
sed -e "s#/sys/class/dmi/id/board_name#$WORK/board_name#" \
	-e "s#\. /etc/os-release#. $WORK/os-release#" \
	-e "s#^LCD_TEMPLATE=.*#LCD_TEMPLATE=\${TEST_LCD_TEMPLATE}#" \
	"$REPO_DIR/install-RefreshRateUnlocker.sh" > "$WORK/install.sh"

PROFILE="$WORK/home/.config/gamescope/scripts/valve.steamdeck.lcd.70Hz.lua"

# run_installer <board> <version> <menu choice> [profile path]
run_installer() {
	echo "$1" > "$WORK/board_name"
	printf 'VERSION_ID=%s\n' "$2" > "$WORK/os-release"
	env -i PATH="$WORK/bin:/usr/bin:/bin" HOME="$WORK/home" WAYLAND_DISPLAY=wayland-0 \
		ZENITY_CHOICE="$3" TEST_LCD_TEMPLATE="${4:-$WORK/lcd.lua}" bash "$WORK/install.sh" 2>&1
}

# 1. install on current SteamOS
OUT=$(run_installer Jupiter 3.9.5 INSTALL)
if [ -f "$PROFILE" ] && echo "$OUT" | grep -q "successfully installed"
then pass "install on SteamOS 3.9.5"; else fail "install on SteamOS 3.9.5"; echo "$OUT"; fi

# 2. generated profile allows 40..70Hz and nothing else changed
EXPECTED="$(seq 40 70 | paste -sd, | sed 's/,/, /g')"
if grep -qF "$EXPECTED" "$PROFILE" 2> /dev/null
then pass "profile contains 40..70Hz"; else fail "profile contains 40..70Hz"; fi
if diff <(grep -v -E '^[[:space:]]*[0-9]+(,[[:space:]]*[0-9]+)*,?[[:space:]]*$' "$WORK/lcd.lua") \
	<(grep -v -E '^[[:space:]]*[0-9]+(,[[:space:]]*[0-9]+)*,?[[:space:]]*$' "$PROFILE") > /dev/null 2>&1
then pass "rest of the profile is unchanged"; else fail "rest of the profile is unchanged"; fi

# 3. generated profile is valid Lua (if a Lua interpreter is available)
LUA=$(command -v lua5.4 || command -v lua5.3 || command -v lua || command -v luajit)
if [ -n "$LUA" ]
then
	if "$LUA" -e 'gamescope={config={known_displays={}},eotf={gamma22=0},modegen={}} function debug() end' \
		-e "dofile('$PROFILE')" \
		-e 'local r=gamescope.config.known_displays.steamdeck_lcd.dynamic_refresh_rates assert(r[1]==40 and r[#r]==70 and #r==31)'
	then pass "profile is valid Lua with 31 rates"; else fail "profile is valid Lua with 31 rates"; fi
else
	echo "SKIP: no Lua interpreter"
fi

# 4. future SteamOS versions work without a script update
OUT=$(run_installer Jupiter 3.12.1 INSTALL)
if echo "$OUT" | grep -q "successfully installed"
then pass "install on future SteamOS 3.12.1"; else fail "install on future SteamOS 3.12.1"; fi

# 5. uninstall removes the profile
OUT=$(run_installer Jupiter 3.9.5 UNINSTALL)
if [ ! -e "$PROFILE" ] && echo "$OUT" | grep -q "successfully removed"
then pass "uninstall"; else fail "uninstall"; fi

# 6. Steam Deck OLED is rejected
OUT=$(run_installer Galileo 3.9.5 INSTALL)
if [ ! -e "$PROFILE" ] && echo "$OUT" | grep -q "OLED detected"
then pass "OLED rejected"; else fail "OLED rejected"; fi

# 7. missing stock profile is rejected
OUT=$(run_installer Jupiter 3.9.5 INSTALL "$WORK/missing.lua")
if [ ! -e "$PROFILE" ] && echo "$OUT" | grep -q "unsupported version"
then pass "missing gamescope profile rejected"; else fail "missing gamescope profile rejected"; fi

# 8. a profile in an unexpected format is not "successfully installed"
grep -v dynamic_refresh_rates "$WORK/lcd.lua" > "$WORK/broken.lua"
OUT=$(run_installer Jupiter 3.9.5 INSTALL "$WORK/broken.lua")
if [ ! -e "$PROFILE" ] && echo "$OUT" | grep -q "NOT successfully installed"
then pass "unexpected profile format rejected"; else fail "unexpected profile format rejected"; fi

# 9. cancel makes no changes
OUT=$(run_installer Jupiter 3.9.5 EXIT)
if [ ! -e "$PROFILE" ] && echo "$OUT" | grep -q "Make no changes"
then pass "cancel makes no changes"; else fail "cancel makes no changes"; fi

# 10. the .desktop launcher points to bootstrap.sh of this repository
if grep -q '^Exec=konsole --hold -e bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/ahtynarg/SteamDeck-RefreshRateUnlocker/main/bootstrap.sh)"$' "$REPO_DIR/RefreshRateUnlocker.desktop"
then pass ".desktop launcher command"; else fail ".desktop launcher command"; fi

# 11. both copies of the installer are identical
if cmp -s "$REPO_DIR/install-RefreshRateUnlocker.sh" "$REPO_DIR/70HzLCD.sh"
then pass "70HzLCD.sh matches install-RefreshRateUnlocker.sh"; else fail "70HzLCD.sh matches install-RefreshRateUnlocker.sh"; fi

[ $FAILED -eq 0 ] && echo "All tests passed." || echo "Some tests FAILED."
exit $FAILED
