# slightly safer rm
alias rm='rm -I'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# use absolute paths for wsltty UI features e.g. ctrl+click paths
set -P

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

