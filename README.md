# setup-unix: Linux Mint 21.3
My setup on Linux Mint 21.3

## Preview

![Preview](./.setup-unix.png)

The terminal emulator is [WezTerm](https://wezfurlong.org/wezterm/index.html).

The font is [Fira Mono NerdFont](https://github.com/mozilla/Fira) which is already patched with powerline symbols.

The programs being run are [tmux](https://github.com/tmux/tmux) for multiplexing
the various shells, [neovim](https://github.com/neovim/neovim) for editing, and
bash for the shell, all set up using the configurations in this repo.

## Setup

```bash
# update/upgrade
sudo apt update -y && sudo apt upgrade -y

# copy Firefox profiles over
# see: https://support.mozilla.org/en-US/kb/recovering-important-data-from-an-old-profile#w_bookmarks-downloads-and-browsing-history

# install vendor-specific drivers
# e.g. for a Razer Blade, install OpenRazer packages:
# see: https://openrazer.github.io/#ubuntu
sudo apt install -y software-properties-gtk
sudo add-apt-repository -y ppa:openrazer/stable
sudo apt update -y && sudo apt install --install-suggests -y openrazer-meta

# install KeepassXC
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.keepassxc.KeePassXC
# import your KeepassXC db file

# install neovim
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt update -y && sudo apt install -y neovim
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60

# install APT packages
sudo apt install -y tmux pipx python3-pynvim gawk git firetools shfmt
# (no need to run `pipx ensurepath`, it's already set in ~/.profile)

# install more APT packages (required by pyenv)
sudo apt install -y build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# install ytp-dlp, Pygments
pipx install yt-dlp[default]
pipx install Pygments

# install pyenv
curl -fsSL https://pyenv.run | bash

# install pipenv
pip install pipenv --user

# copy SSH keys to .ssh and then:
mkdir ~/.ssh/sockets

# install FiraMonoNerdFont
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraMono.zip -P ~/Downloads
mkdir -p ~/.fonts
unzip ~/Downloads/FiraMono.zip -d ~/.fonts/FiraMonoNerdFont
fc-cache -fv

# verify FiraMonoNerdFont installation
fc-list | grep "FiraMono Nerd Font Mono"

# install wezterm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update -y && sudo apt install -y wezterm
# below command doesn't seem to work in Mint. Set in "Preferred Applications" instead.
#sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/open-wezterm-here 60

# install vscodium
# see: https://vscodium.com/#use-a-package-manager-deb-rpm-provided-by-vscodium-related-repos

# install BeyondCompare
wget https://www.scootersoftware.com/files/bcompare-4.4.7.28397_amd64.deb -P ~/Downloads
sudo apt update -y && sudo apt install -y ~/Downloads/bcompare-4.4.7.28397_amd64.deb

# install Joplin using the suggested method (script updates the .appimage if already present)
# https://joplinapp.org/help/install/
# import data, or copy old `joplin-desktop` directory to ~/.config/

# set static IP for printer and test using driverless printing/scanning
# see: https://forums.linuxmint.com/viewtopic.php?p=1663963#p1663963
sudo gpasswd -a $USER lp
sudo gpasswd -a $USER lpadmin

# setup dotfiles
# IMPORTANT: set GITHUB_USER to your main GitHub username
GITHUB_USER=CoeJoder
SETUP_UNIX_DIR="$HOME/projects/github/$GITHUB_USER/setup-unix"
mkdir -p $SETUP_UNIX_DIR
git clone https://github.com/CoeJoder/setup-unix.git $SETUP_UNIX_DIR
pushd $SETUP_UNIX_DIR
git branch -a
git checkout Mint21_3

# deploy git configs, switch to git+ssh, deploy the rest
./scripts/deploy_setup_unix.sh --bootstrap
git remote set-url origin "github.com_$GITHUB_USER:CoeJoder/setup-unix.git"
git submodule update --init --recursive
./scripts/deploy_setup_unix.sh --all
popd

# setup NodeJS
n lts
npm_g install

# setup neovim plugins
nvim
:UpdateRemotePlugins
:TransparentEnable
# the previous command may give innocuous error message;
# restart neovim to see if transparency is working

# setup joplin sandboxing
sed -i 's|Exec=.*|Exec=/bin/bash -c "firejail --appimage --profile=joplin --nosound "$HOME/.joplin/Joplin.AppImage""|g' ~/.local/share/applications/appimagekit-joplin.desktop
update-desktop-database
# start Joplin and set the backup directory to ~/.config/joplin-desktop/JoplinBackup
# before quitting Joplin, verify that it is listed here:
# firejail --list

# install BackInTime
sudo add-apt-repository -y ppa:bit-team/stable
sudo apt update -y && sudo apt install -y backintime-qt

# reboot
sudo reboot
```

## Post-setup

- verify the above settings are applied
- enable Gufw ("Firewall Configuration" app)
  - default "Home" profile
- setup Timeshift snapshots
  - default includes/excludes
  - Monthly: 1, Weekly: 1, Daily: 7
- setup BackInTime snapshots
  - include: /home/[user]
  - default excludes
  - Custom hours: 12,22
- schedule periodic Foxclone full-disk backups
- test restoration of Timeshift/BackInTime snapshots in a Mint VM
- test restoration of Foxclone backup via file-to-drive clone in a VM

## Using git+ssh
- to work as multiple users per host across projects, git-ssh is configured based on the project directory.  See:
  - ~/.ssh/config
  - ~/.config/git/config
- projects should be cloned using `gitssh_clone()`, e.g:
    - `gitssh_clone git@github.com:torvalds/linux.git`

### IMPORTANT
Ensure git and ssh configs are correct at this point.
