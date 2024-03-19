#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJ_DIR="$(readlink -f "$SCRIPT_DIR/../")"

echo "Deploying the dotfiles..."
rsync -avh $PROJ_DIR/ ~

echo "Overriding with private configs..."
GIT_CONFIG=~/.config/git/config
GIT_CONFIG_PRIV=${GIT_CONFIG}.priv
if [ -f $GIT_CONFIG_PRIV ]; then
    cp -v $GIT_CONFIG_PRIV $GIT_CONFIG
else
    echo "$GIT_CONFIG_PRIV not found, skipping..."
fi
