#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJ_DIR="$(readlink -f "$SCRIPT_DIR/../")"

if [[ ~ -ef $PROJ_DIR ]]; then
    echo "must run from cloned dir, not deployment destination" >&2
    exit 1
fi
if [[ $1 == '-h' ]] ; then
    echo "usage: deploy_setup_unix --bootstrap" >&2
    echo "       deploy_setup_unix [--all]" >&2
    exit 0
fi

if [[ $1 == '--bootstrap' ]] ; then
    echo "Bootstrapping git config..."
    rsync -avh ./.config/git/ ~/.config/git
else
    if [[ $1 != '--all' ]]; then
        RSYNC_OPTS='--update'
        echo "Deploying the dotfiles..."
    fi
    rsync -avh $RSYNC_OPTS --exclude-from="$SCRIPT_DIR/excludes.txt" $PROJ_DIR/ ~
fi

echo "Overriding with private git configs..."
GIT_CONFIG=~/.config/git/config
GIT_CONFIG_PRIV=${GIT_CONFIG}.priv
if [ -f $GIT_CONFIG_PRIV ]; then
    rsync -tgovh $GIT_CONFIG_PRIV $GIT_CONFIG
else
    echo "$GIT_CONFIG_PRIV not found, skipping..."
fi
