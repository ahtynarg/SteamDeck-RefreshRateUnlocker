#!/bin/bash
# Downloads (or updates) SteamDeck-RefreshRateUnlocker and starts the installer.
# Used by RefreshRateUnlocker.desktop so the mod can be installed without typing commands.

REPO_URL=${RRU_REPO_URL:-https://github.com/ahtynarg/SteamDeck-RefreshRateUnlocker.git}
INSTALL_DIR=${RRU_INSTALL_DIR:-$HOME/SteamDeck-RefreshRateUnlocker}

normalize_url() {
	echo "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's#\.git$##' -e 's#/$##'
}

if [ -d "$INSTALL_DIR/.git" ] && [ "$(normalize_url "$(git -C "$INSTALL_DIR" remote get-url origin 2> /dev/null)")" == "$(normalize_url "$REPO_URL")" ]
then
	echo Updating $INSTALL_DIR
	if ! git -C "$INSTALL_DIR" pull --ff-only
	then
		echo Could not update - continuing with the version already downloaded.
	fi
else
	# an older copy (for example a clone of the original project) - keep it, just move it aside
	if [ -e "$INSTALL_DIR" ]
	then
		BACKUP="$INSTALL_DIR.backup-$(date +%Y%m%d-%H%M%S)"
		echo Moving the existing $INSTALL_DIR to $BACKUP
		mv "$INSTALL_DIR" "$BACKUP" || exit 1
	fi

	echo Downloading $REPO_URL
	if ! git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
	then
		echo Download failed. Check the internet connection and try again.
		exit 1
	fi
fi

exec "$INSTALL_DIR/install-RefreshRateUnlocker.sh"
