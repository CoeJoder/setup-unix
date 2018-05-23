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
    ssh joe@pve.local "/bin/bash -s -- $@" < ~/scripts/vm.sh
}
