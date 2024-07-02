# n installs node and npm
export N_PREFIX="$HOME/.local"

# disable terminal audio beeps
bind 'set bell-style none'

# slightly safer rm
alias rm='rm -I'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# interpret color characters
export LESS='-R'
export PYGMENTIZE_STYLE='paraiso-dark'

# sometimes needed for X forwarding over SSH
#export DISPLAY=localhost:0

# git-aware bash prompt
GIT_PROMPT_THEME="Custom"
GIT_PROMPT_ONLY_IN_REPO=0
GIT_PROMPT_FETCH_REMOTE_STATUS=0
source ~/.bash-git-prompt/gitprompt.sh

# ensure agent is running
# see: https://stackoverflow.com/a/48509425/159570
ssh-add -l &>/dev/null
if [ "$?" == 2 ]; then
    # Could not open a connection to your authentication agent.

    # Load stored agent connection info.
    test -r ~/.ssh-agent && \
        eval "$(<~/.ssh-agent)" >/dev/null

    ssh-add -l &>/dev/null
    if [ "$?" == 2 ]; then
        # Start agent and store agent connection info.
        (umask 066; ssh-agent > ~/.ssh-agent)
        eval "$(<~/.ssh-agent)" >/dev/null
    fi
fi

# add a SSH key to the agent
_ssh_add() {
    if [ -f "$1" ]; then
        ssh-add -t 1d "$1"
    else
        echo "SSH key not found: $1"
    fi
}

# load Github SSH key
gitssh() {
    _ssh_add ~/.ssh/id_ed25519_github
}

# load Vultr SSH key
vultrssh() {
    _ssh_add ~/.ssh/id_ed25519_vultr
}

# work with npm in ~/.npm_globals
npm_g() {
    (cd ~/.npm_global && npm $@)
}

# kill all tmux session except the current one
tmux_killall() {
    tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' | \
        xargs -n 1 tmux kill-session -t || echo No sessions to kill
}

# print the external IP address to stdout
whatismyip() {
    echo "$(curl -kLs https://ipinfo.io/ip)"
}

# fetch and pygmentize a URL document to stdout
pyget() {
    local PYG_PYTHON="$HOME/.local/pipx/venvs/pygments/bin/python"
    local PYGTERMINIZE="$HOME/scripts/pygterminize.py"
    if [[ ! -f $PYG_PYTHON ]] ; then
        echo "Not found: $PYG_PYTHON" >&2
        return 1
    fi
    if [[ ! -f $PYGTERMINIZE ]] ; then
        echo "Not found: $PYGTERMINIZE" >&2
        return 1
    fi
    if ! type -P wget >/dev/null 2>&1; then
        echo "Command 'wget' not found" >&2
        return 1
    fi
    if [[ ! -v PYGMENTIZE_STYLE ]] ; then
        echo "PYGMENTIZE_STYLE not set" >&2
        return 1
    fi
    if [[ $# -ne 1 ]] ; then
        echo "usage: pyget url" >&2
        return 1
    fi
    local URL="$1"
    (
        set -euo pipefail
        wget -q --show-progress -O - "$URL" | \
        "$PYG_PYTHON" "$PYGTERMINIZE" -u "$URL" -s "$PYGMENTIZE_STYLE"
    )
}

# fetch and pygmentize a URL document to less
lessget() {
    if [[ $# -lt 1 ]] ; then
        echo "usage: lessget [LESS_OPTIONS] url" >&2
        return 1
    fi
    if [[ $# -gt 1 ]] ; then
        local LESS_OPTIONS="${@: 1:$#-1}"
    fi
    local URL="${@: -1}"
    # use a temp file to handle large docs
    (
        set -eo pipefail
        TEMPFILE=$(mktemp)
        trap "rm -f ${TEMPFILE@Q}" EXIT
        pyget "$URL" > "$TEMPFILE"
        less $LESS_OPTIONS "$TEMPFILE"
    )
}

# start tmux with the current environment
if [ "$TMUX" = "" ] && [ "$SKIP_TMUX" != 0 ]; then tmux -L default; fi

