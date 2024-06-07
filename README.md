# setup-unix: Linux Mint 21.3
My standard setup on Linux Mint 21.3

### Preview

![Preview](./.setup-unix.png)

The terminal emulator is [WezTerm](https://wezfurlong.org/wezterm/index.html).

The font is [Fira Mono NerdFont](https://github.com/mozilla/Fira) which is already patched with powerline symbols.

The programs being run are [tmux](https://github.com/tmux/tmux) for multiplexing
the various shells, [neovim](https://github.com/neovim/neovim) for editing, and
bash for the shell, all set up using the configurations in this repo.

### Usage

```bash
# update/upgrade
sudo apt update -y && sudo apt upgrade -y

# set timezone
sudo timedatectl set-timezone America/Los_Angeles

# copy Firefox profiles over
# see: https://support.mozilla.org/en-US/kb/recovering-important-data-from-an-old-profile#w_bookmarks-downloads-and-browsing-history

# install vendor-specific drivers
# e.g. for a Razer Blade, install OpenRazer packages:
# see: https://openrazer.github.io/#ubuntu
sudo apt install -y software-properties-gtk
sudo add-apt-repository ppa:openrazer/stable
sudo apt update -y && sudo apt install --install-suggests -y openrazer-meta

# install KeepassXC
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user flathub org.keepassxc.KeePassXC
# import your KeepassXC db file

# install neovim
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt update -y && sudo apt install neovim
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60

# install tmux, pipx, pynvim, gawk
sudo apt install -y tmux pipx python3-pynvim gawk
# (no need to run `pipx ensurepath`, it's already set in ~/.profile)

# install ytp-dlp
pipx install yt-dlp[default]

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

# install git
sudo apt install -y git

# install BeyondCompare
wget https://www.scootersoftware.com/files/bcompare-4.4.7.28397_amd64.deb -P ~/Downloads
sudo apt update -y && sudo apt install -y ~/Downloads/bcompare-4.4.7.28397_amd64.deb

# set static IP for printer and test using driverless printing/scanning
# see: https://forums.linuxmint.com/viewtopic.php?p=1663963#p1663963
sudo gpasswd -a $USER lp
sudo gpasswd -a $USER lpadmin

# setup git site-user project dir structure
# IMPORTANT: set GITHUB_USER to your main github username
GITHUB_USER=CoeJoder
GITHUB_PROJ_DIR="~/projects/github/$GITHUB_USER"
mkdir -p $GITHUB_PROJ_DIR

# setup dotfiles
git clone --recurse-submodules git@github.com:CoeJoder/setup-unix.git $GITHUB_PROJ_DIR/setup-unix
pushd $GITHUB_PROJ_DIR/setup-unix
git submodule update --init --recursive

# IMPORTANT: edit/rename `.config/git/config.github.CoeJoder` to `.config/git/config.github.[your-main-github-user]`
# Optional: add any additional `.config/git/config.[site].[user]`

# IMPORTANT: edit `.config/git/config` and change paths as needed
# Optional: add any additional entries such as:
#   [includeIf "gitdir:~/projects/[site]/[user]/**"]
#     path = ~/.config/git/config.[site].[user]

# NOTE: when cloning projects, the SSH user creds will be chosen based on gitdir,
# but this also requires local address-rewriting.  To make this work, follow these guidelines:
#
#   - Clone projects into `~/projects/[site]/[user]/[project]`
#   - When cloning, instead of:
#       `git clone [gitssh-endpoint]:[remote-user]/[project].git`
#     Do:
#       `git clone [site]_[user]:[remote-user]/[project].git ~/projects/[site]/[user]/[project]`
#   - Example:
#       `git clone github_CoeJoder:torvalds/linux.git ~/projects/github/CoeJoder/linux`

# deploy dotfiles & substitute private configs
# IMPORTANT: This WILL overwrite existing files; backup recommended.
./scripts/deploy_setup_unix.sh
popd

# setup NodeJS
n lts
npm_g install

# install syntax highlighter for `less`
pipx install Pygments
# if already installed:
pipx upgrade Pygments

# setup neovim plugins
nvim
:UpdateRemotePlugins
:TransparentEnable
# the previous command may give innocuous error message;
# restart neovim to see if transparency is working

# reboot
sudo reboot
```

