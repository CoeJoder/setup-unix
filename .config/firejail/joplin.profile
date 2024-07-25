# Firejail profile for joplin
# Description: Joplin note-taking application
# Original profile: https://github.com/netblue30/firejail/issues/1139#issuecomment-1956468208
# My changes: minor fixes marked "[CJ]", and persistent local customizations
# Launch command:
#   firejail --appimage --profile=joplin --nosound "$HOME/.joplin/Joplin.AppImage"

# Persistent local customizations
include joplin.local

#   NOBLACKLISTS
noblacklist ${HOME}/.config/Electron
noblacklist ${HOME}/.config/electron*-flag*.conf
# [CJ]
noblacklist ${HOME}/.config/Joplin
noblacklist ${HOME}/.config/joplin-desktop
noblacklist ${HOME}/.config

#   ALLOW INCLUDES
#   BLACKLISTS
blacklist /usr/libexec

#   DISABLE INCLUDES
include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-programs.inc
include disable-xdg.inc
include disable-shell.inc

# content of disable-exec.inc - removed noexec /tmp, prevented joplin from starting
noexec ${HOME}
noexec ${RUNUSER}
noexec /dev/mqueue
noexec /dev/shm
noexec /run/shm
noexec /var

include chromium-common-hardened.inc.profile

#   NOWHITELISTS

#   MKDIRS
mkdir ${HOME}/.config/Joplin
mkdir ${HOME}/.config/joplin-desktop

#   WHITELISTS
whitelist ${HOME}/.config/Joplin
whitelist ${HOME}/.config/joplin-desktop
whitelist ${DOWNLOADS}
whitelist ${HOME}/.config/Electron
whitelist ${HOME}/.config/electron*-flag*.conf

#   WHITELIST INCLUDES
include whitelist-runuser-common.inc
include whitelist-var-common.inc

#   OPTIONS (caps*, net*, no*, protocol, seccomp*, shell none, tracelog)
caps.keep sys_admin,sys_chroot
netfilter
nodvd
nogroups
noinput
notv
nou2f
novideo

#   PRIVATE OPTIONS (disable-mnt, private-*, writable-*)
disable-mnt
private-cache
private-tmp

#   DBUS FILTER
dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-system none

#   SPECIAL OPTIONS
# [CJ] applied to .desktop launcher by install script
env APPIMAGELAUNCHER_DISABLE=TRUE
