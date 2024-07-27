# projects directory
export PROJECTS_DIR="$HOME/projects"
if [[ ! -d $PROJECTS_DIR ]] ; then
    mkdir -p "$PROJECTS_DIR"
fi 

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

# in-place shell selection list
# source: https://askubuntu.com/a/1386907
function choose_from_menu() {
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=0 count=${#options[@]} index=0
    local esc=$(echo -en "\e") # cache ESC as test doesn't allow esc codes
    printf "$prompt\n"
    while true
    do
        # list all options (option list is zero-based)
        index=0 
        for o in "${options[@]}"
        do
            if [ "$index" == "$cur" ]
            then echo -e " >\e[7m$o\e[0m" # mark & highlight the current option
            else echo "  $o"
            fi
            index=$(( $index + 1 ))
        done
        read -s -n3 key # wait for user to key in arrows or ENTER
        if [[ $key == $esc[A ]] # up arrow
        then cur=$(( $cur - 1 ))
            [ "$cur" -lt 0 ] && cur=0
        elif [[ $key == $esc[B ]] # down arrow
        then cur=$(( $cur + 1 ))
            [ "$cur" -ge $count ] && cur=$(( $count - 1 ))
        elif [[ $key == "" ]] # nothing, i.e the read delimiter - ENTER
        then break
        fi
        echo -en "\e[${count}A" # go up to the beginning to re-render
    done
    # export the selection to the requested output variable
    printf -v $outvar "${options[$cur]}"
}

# given a gitssh-endpoint, clones a git repo using gitdir-ssh mapping/rewriting
gitssh-clone() {
    if [[ -z $PROJECTS_DIR ]] ; then
        echo "PROJECTS_DIR not set" >&2
    fi
    if [[ $# -ne 1 ]] ; then
        echo "usage: gitclone gitssh-endpoint" >&2
        return 1
    fi
    local regex='git@([^:]*):([^/]*)/(.*?)\.git'
    if [[ ! $1 =~ $regex ]]; then
        echo "unrecognized gitssh-endpoint format" >&2
        return 1
    fi
    local local_gituser
    read -p "Local git user: " local_gituser
    if [[ -z $local_gituser ]] ; then
        echo "invalid username" >&2
        return 1
    fi
    local hostname="${BASH_REMATCH[1]}"
    local remote_gituser="${BASH_REMATCH[2]}"
    local project="${BASH_REMATCH[3]}"
    local fields
    IFS='.' read -a fields <<< "$hostname"
    local site="${fields[-2]}"
    echo -e "Site: $site\nProject: $remote_gituser/$project"
    dest_dir="$PROJECTS_DIR/$site/$local_gituser/$project"
    read -p "Clone into $dest_dir? (y/N): " confirm && \
        [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return 1
    git clone "${site}_$local_gituser:$remote_gituser/$project.git" "$dest_dir"
    echo "pushd $dest_dir..."
    pushd "$dest_dir" > /dev/null
}

# terminal-only, url-aware alternative to `pygmentize` with enhanced lexer guessing
pygterminize() {
    local PYGMENTS_PYTHON="$HOME/.local/pipx/venvs/pygments/bin/python"
    local PYGTERMINIZE="$HOME/scripts/pygterminize.py"
    if [[ ! -f $PYGMENTS_PYTHON ]] ; then
        echo "not found: $PYGMENTS_PYTHON" >&2
        return 1
    fi
    if [[ ! -f $PYGTERMINIZE ]] ; then
        echo "not found: $PYGTERMINIZE" >&2
        return 1
    fi
    "$PYGMENTS_PYTHON" "$PYGTERMINIZE" $@
}

# fetch and pygmentize a URL document to stdout
pyget() {
    if ! type -P wget >/dev/null 2>&1; then
        echo "command 'wget' not found" >&2
        return 1
    fi
    if [[ $# -ne 1 ]] ; then
        echo "usage: pyget url" >&2
        return 1
    fi
    local URL="$1"
    (
        set -euo pipefail
        wget -q --show-progress -O - "$URL" | pygterminize -u "$URL"
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

