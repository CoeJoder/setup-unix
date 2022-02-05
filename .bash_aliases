# slightly safer rm
alias rm='rm -I'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# use absolute paths for wsltty UI features e.g. ctrl+click paths
set -P

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

# load identities
ssh-add -l &>/dev/null
if [ "$?" == 1 ]; then
    # The agent has no identities.
    # Time to add one.
    if [ -f ~/.ssh/id_ed25519_github ]; then
        ssh-add -t 1d ~/.ssh/id_ed25519_github
    fi
fi

# work with npm in ~/.npm_globals
npm_g() {
    (cd ~/.npm_global && npm $@)
}

# VM convenience method
vm() {
    (/bin/bash ~/scripts/vm.sh $@)
    #ssh joe@pve.local "/bin/bash -s -- $@" < ~/scripts/vm.sh
}

# VM bash autocompletion
_vm_autocomplete() {
    local cur all_options vms
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    all_options="start shutdown reset suspend resume stop status vnc spice listvms"

    if [[ "${COMP_CWORD}" == 1 ]]; then
        COMPREPLY=( $(compgen -W "${all_options}" -- ${cur}) )
        return 0
    elif [[ "${COMP_CWORD}" == 2 ]]; then
        vms="$(vm listvms)"
        COMPREPLY=( $(compgen -W "${vms}" -- ${cur}) )
        return 0
    fi
}
complete -F _vm_autocomplete vm

# kill all tmux session except the current one
tmux_killall() {
    tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' | xargs -n 1 tmux kill-session -t || echo No sessions to kill
}

# start tmux with the current environment
if [ "$TMUX" = "" ] && [ "$SKIP_TMUX" != 0 ]; then tmux -L default; fi

