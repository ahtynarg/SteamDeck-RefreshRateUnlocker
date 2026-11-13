#!/bin/bash

clear

echo Steam Deck Refresh Rate Unlocker / 70Hz LCD mod script  by ryanrudolf
echo https://github.com/ryanrudolfoba/SteamDeck-RefreshRateUnlocker
echo YT - 10MinuteSteamDeckGamer
echo Fork updated for current SteamOS releases \(3.7, 3.8, 3.9 and newer\).
sleep 2

# always work relative to the folder where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# capture SteamOS version and Steam Deck model
MODEL=$(cat /sys/class/dmi/id/board_name 2> /dev/null)
STEAMOS_VERSION_FULL=$(. /etc/os-release && echo "$VERSION_ID")
STEAMOS_VERSION=$(echo "$STEAMOS_VERSION_FULL" | cut -d "." -f1-2)

# refresh rate range that will be exposed to the Steam client
MIN_HZ=40
MAX_HZ=70

# SteamOS 3.7 and above unlock method using a custom gamescope LUA display profile
LCD_TEMPLATE=/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua
SCRIPT_LOCATION="${XDG_CONFIG_HOME:-$HOME/.config}/gamescope/scripts"
SCRIPT_NAME=valve.steamdeck.lcd.70Hz.lua

# SteamOS 3.6.20 unlock method using patched gamescope
# GS=GAMESCOPE
GS_ORIG="$SCRIPT_DIR/gamescope/3.6.20/gamescope-3.6.20-orig"
GS_PATCHED="$SCRIPT_DIR/gamescope/3.6.20/gamescope-3.6.20-patched"
GS_ORIG_MD5SUM=c522838a242fabe519958903253a2a4c
GS_PATCHED_MD5SUM=641af753637c710f72748d4ec7fb655b

# returns success if version $1 >= version $2 (handles 3.10 > 3.9 correctly)
version_ge() {
	[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n 1)" == "$2" ]
}

# pick the unlock method for the running SteamOS version
if version_ge "$STEAMOS_VERSION" 3.7
then
	METHOD=LUA
elif [ "$STEAMOS_VERSION_FULL" == "3.6.20" ]
then
	METHOD=GAMESCOPE_BINARY
elif [ "$STEAMOS_VERSION" == "3.5" ]
then
	METHOD=GAMESCOPE_SESSION
else
	METHOD=UNSUPPORTED
fi

# go back to Game Mode using the official SteamOS helper, fall back to a KDE logout
return_to_game_mode() {
	echo Returning to Game Mode in 5sec.
	sleep 5
	if command -v steamos-session-select &> /dev/null
	then
		steamos-session-select gamescope
	elif command -v qdbus6 &> /dev/null
	then
		qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
	elif command -v qdbus &> /dev/null
	then
		qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
	else
		echo Could not switch automatically. Use the \"Return to Gaming Mode\" shortcut on the desktop.
	fi
}

report_issue() {
	echo Please open an issue report on the GitHub repo and include the output above.
}

# sanity check - are you running this in Desktop Mode or ssh / virtual tty session?
# Desktop Mode is Wayland by default since SteamOS 3.8, so do not rely on X11 tools.
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]
then
	echo Script is running in Desktop Mode.
else
	echo Script is NOT running in Desktop Mode.
	echo Please run the script in Desktop Mode as mentioned in the README. Goodbye!
	exit 1
fi

if ! command -v zenity &> /dev/null
then
	echo zenity was not found. It is required for the dialogs. Goodbye!
	exit 1
fi

# sanity checks - make sure this is on Valve Steam Deck LCD and running on supported SteamOS version.
if [ "$MODEL" != "Jupiter" ]
then
	if [ "$MODEL" == "Galileo" ]
	then
		echo Steam Deck OLED detected. This mod is for the Steam Deck LCD only.
	else
		echo This is not a Steam Deck LCD \(board: ${MODEL:-unknown}\). Goodbye!
	fi
	exit 1
fi

if [ "$METHOD" == "UNSUPPORTED" ]
then
	echo SteamOS $STEAMOS_VERSION_FULL detected. This is unsupported version.
	exit 1
fi
echo Test 1. Steam Deck LCD on SteamOS $STEAMOS_VERSION_FULL detected. Proceed to the next step.

# sanity check - the older methods modify system files and need the sudo password.
# The LUA method (SteamOS 3.7+) only writes to the home folder, so no sudo is needed.
if [ "$METHOD" != "LUA" ]
then
	if [ "$(passwd --status $(whoami) | tr -s " " | cut -d " " -f 2)" == "P" ]
	then
		read -s -p "Please enter current sudo password: " current_password ; echo
		echo Checking if the sudo password is correct.
		echo -e "$current_password\n" | sudo -S -k ls &> /dev/null

		if [ $? -eq 0 ]
		then
			echo Sudo password is good!
		else
			echo Sudo password is wrong! Re-run the script and make sure to enter the correct sudo password!
			exit 1
		fi
	else
		echo Sudo password is blank! Setup a sudo password first and then re-run script!
		passwd
		exit 1
	fi
fi

# sanity checks are all good. lets go!
# display warning / disclaimer
zenity --question --title "Steam Deck Refresh Rate Unlocker" --text \
	"WARNING: This is for educational and research purposes only! \
	\n\nThe script has been tested with Steam Deck LCD and the original LCD panel. \
	\nThis may / may not work with and may / may not cause damage to a DeckHD / DeckSight panel. \
	\n\nIf you use a DeckHD / DeckSight panel then proceed at your own risk! \
	\n\nThe author of this script takes no responsibility for any damage. \
	\n\nDo you agree to the terms and conditions ?" --width 700 --height 75
if [ $? -ne 0 ]
then
	echo User DOES NOT agree with the terms and conditions. Exit immediately.
	exit
else
	echo User agrees to the terms and conditions. Continue with the script.
fi


###### Main menu. Ask user to UNINSTALL or INSTALL

Choice=$(zenity --width 700 --height 220 --list --radiolist --title "Refresh Rate Unlocker - SteamOS $STEAMOS_VERSION_FULL" \
	--column "Select One" \
	--column "Refresh Rate Limit" \
	--column="Description - Read this carefully!" \
	FALSE INSTALL "Install the ${MAX_HZ}Hz mod." \
	FALSE UNINSTALL "Remove the ${MAX_HZ}Hz mod." \
	TRUE EXIT "Don't make any changes and exit immediately.")

if [ $? -ne 0 ] || [ "$Choice" == "EXIT" ] || [ -z "$Choice" ]
then
	echo User pressed CANCEL / EXIT. Make no changes. Exiting immediately.
	exit

elif [ "$Choice" == "INSTALL" ]
then
	if [ "$METHOD" == "LUA" ]
	then
		echo Installing the ${MAX_HZ}Hz mod for SteamOS $STEAMOS_VERSION_FULL.

		if [ ! -e "$LCD_TEMPLATE" ]
		then
			echo Default Gamescope template not found: $LCD_TEMPLATE
			report_issue
			exit 1
		fi

		mkdir -p "$SCRIPT_LOCATION"

		# build the list of refresh rates MIN_HZ..MAX_HZ, e.g. "40, 41, ..., 70"
		RATES=$(seq $MIN_HZ $MAX_HZ | paste -sd, | sed 's/,/, /g')

		# copy the stock profile and replace only the dynamic_refresh_rates block.
		# This does not depend on the exact line layout of the stock file.
		TMP_FILE=$(mktemp)
		awk -v rates="$RATES" '
			/dynamic_refresh_rates[[:space:]]*=[[:space:]]*{/ {
				print "    dynamic_refresh_rates = {"
				print "        " rates
				print "    },"
				skipping = 1
				replaced++
				# block opened and closed on the same line
				if ($0 ~ /}/) skipping = 0
				next
			}
			skipping {
				if ($0 ~ /}/) skipping = 0
				next
			}
			{ print }
			END { if (replaced != 1) exit 1 }
		' "$LCD_TEMPLATE" > "$TMP_FILE"

		if [ $? -eq 0 ] && grep -q "$MAX_HZ" "$TMP_FILE" && grep -q "steamdeck_lcd" "$TMP_FILE"
		then
			mv "$TMP_FILE" "$SCRIPT_LOCATION/$SCRIPT_NAME"
			echo ${MAX_HZ}Hz LCD mod successfully installed to $SCRIPT_LOCATION/$SCRIPT_NAME
			return_to_game_mode
		else
			rm -f "$TMP_FILE"
			echo ${MAX_HZ}Hz LCD mod NOT successfully installed - the stock gamescope profile has an unexpected format.
			report_issue
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_BINARY" ]
	then
		ACTUAL_GS_ORIG_MD5SUM=$(md5sum "$GS_ORIG" | cut -d " " -f1)
		ACTUAL_GS_PATCHED_MD5SUM=$(md5sum "$GS_PATCHED" | cut -d " " -f1)

		# sanity check - perform md5sum hash check
		if [ "$ACTUAL_GS_ORIG_MD5SUM" == "$GS_ORIG_MD5SUM" ] && [ "$ACTUAL_GS_PATCHED_MD5SUM" == "$GS_PATCHED_MD5SUM" ]
		then
			echo Installing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
			echo Downloaded files contain a valid md5sum hash.
			echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
			echo -e "$current_password\n" | sudo -S cp "$GS_PATCHED" /usr/bin/gamescope
			if [ $? -eq 0 ] && [ "$(md5sum /usr/bin/gamescope | cut -d " " -f 1)" == "$GS_PATCHED_MD5SUM" ]
			then
				echo 70Hz mod successfully installed.
				echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
				return_to_game_mode
			else
				echo Error installing the 70Hz mod.
				echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
				exit 1
			fi
		else
			echo Hash mismatch - possible corrupt download. Clone the repo again!
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_SESSION" ]
	then
		echo Installing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
		echo -e "$current_password\n" | sudo -S sed -i 's/STEAM_DISPLAY_REFRESH_LIMITS=40,60/STEAM_DISPLAY_REFRESH_LIMITS=40,70/g' /bin/gamescope-session
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		if grep -q "STEAM_DISPLAY_REFRESH_LIMITS=40,70" /bin/gamescope-session
		then
			echo 70Hz mod successfully installed.
			return_to_game_mode
		else
			echo Error installing the 70Hz mod.
			exit 1
		fi
	fi

elif [ "$Choice" == "UNINSTALL" ]
then
	if [ "$METHOD" == "LUA" ]
	then
		echo Removing the ${MAX_HZ}Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		rm -f "$SCRIPT_LOCATION/$SCRIPT_NAME"
		echo ${MAX_HZ}Hz mod successfully removed.
		return_to_game_mode

	elif [ "$METHOD" == "GAMESCOPE_BINARY" ]
	then
		echo Removing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
		echo -e "$current_password\n" | sudo -S cp "$GS_ORIG" /usr/bin/gamescope
		if [ $? -eq 0 ] && [ "$(md5sum /usr/bin/gamescope | cut -d " " -f 1)" == "$GS_ORIG_MD5SUM" ]
		then
			echo 70Hz mod successfully removed.
			echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
			exit
		else
			echo Error removing the 70Hz mod.
			echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
			exit 1
		fi

	elif [ "$METHOD" == "GAMESCOPE_SESSION" ]
	then
		echo Removing the 70Hz mod for SteamOS $STEAMOS_VERSION_FULL.
		echo -e "$current_password\n" | sudo -S steamos-readonly disable &> /dev/null
		echo -e "$current_password\n" | sudo -S sed -i 's/STEAM_DISPLAY_REFRESH_LIMITS=40,70/STEAM_DISPLAY_REFRESH_LIMITS=40,60/g' /bin/gamescope-session
		echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
		echo 70Hz mod successfully removed.
		exit
	fi
fi
