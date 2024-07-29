#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJ_DIR="$(readlink -f "$SCRIPT_DIR/../")"

if [[ ~ -ef $PROJ_DIR ]]; then
    printf "This script is intended to be run from the cloned dir, not the deployment destination.\nExiting...\n"
else
    echo "Deploying the dotfiles..."
    if [[ $1 != '--all' ]]; then
        RSYNC_OPTS='--update'
    fi
    rsync -avh $RSYNC_OPTS --exclude-from="$SCRIPT_DIR/excludes.txt" $PROJ_DIR/ ~

    echo "Overriding with private configs..."
    GIT_CONFIG=~/.config/git/config
    GIT_CONFIG_PRIV=${GIT_CONFIG}.priv
    if [ -f $GIT_CONFIG_PRIV ]; then
        rsync -tgovh $GIT_CONFIG_PRIV $GIT_CONFIG
    else
        echo "$GIT_CONFIG_PRIV not found, skipping..."
    fi
fi
