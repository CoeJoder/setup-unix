# setup-unix: Ubuntu Desktop 23.10
My standard setup on Ubuntu Desktop 23.10.

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

# install firefox from Mozilla's DEB repo
# see: https://www.omgubuntu.co.uk/2022/04/how-to-install-firefox-deb-apt-ubuntu-22-04
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
sudo apt update -y && sudo apt install -y firefox

# copy Firefox profiles over
# see: https://support.mozilla.org/en-US/kb/recovering-important-data-from-an-old-profile#w_bookmarks-downloads-and-browsing-history

# install vendor-specific drivers
# e.g. for a Razer Blade, install OpenRazer packages:
# see: https://openrazer.github.io/#ubuntu
sudo apt install -y software-properties-gtk
sudo add-apt-repository ppa:openrazer/stable
sudo add-apt-repository ppa:openrazer/daily
sudo apt update
sudo apt install --install-suggests -y openrazer-meta

# install KeepassXC
sudo add-apt-repository ppa:phoerious/keepassxc
sudo apt update
sudo apt install -y keepassxc
# import your KeepassXC db file

# install pipx
sudo apt update
sudo apt install -y pipx
pipx ensurepath

# install ytp-dlp
pipx install yt-dlp[default]

# copy SSH keys to .ssh and then:
mkdir ~/.ssh/sockets

# install FiraMonoNerdFont
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraMono.zip -P ~/Downloads
unzip ~/Downloads/FiraMono.zip -d ~/.fonts/FiraMonoNerdFont
fc-cache -fv

# verify FiraCodeNerdFont installation
fc-list | grep "FiraCode Nerd Font Mono"

# install wezterm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt upgrade
sudo apt install -y wezterm-nightly
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/open-wezterm-here 60

# install git
sudo apt install -y git

# install BeyondCompare
wget https://www.scootersoftware.com/files/bcompare-4.4.7.28397_amd64.deb -P ~/Downloads
sudo apt update
sudo apt install -y ~/Downloads/bcompare-4.4.7.28397_amd64.deb

# for HP multifunction printer, install universal driver & app
sudo gpasswd -a joe lp
sudo gpasswd -a joe lpadmin
sudo apt install -y hplip
hp-setup

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

# NOTE: when checking out git projects, the SSH user creds will be chosen based on gitdir,
# but this also requires local address-rewriting.  To make this work, follow these guidelines:
#
#   - Clone projects into `~/projects/[site]/[user]/[project]`
#   - When cloning, instead of:
#       `git clone [gitssh-endpoint]:[remote-user]/[project].git`
#     Do:
#       `git clone [site]_[user]:[remote-user]/[project].git ~/projects/[site]/[user]/[project]`
#   - Example:
#       `git clone github_CoeJoder:torvalds/linux.git ~/projects/github/CoeJoder/linux`

# deploy dotfiles
# IMPORTANT: This WILL overwrite existing files; backup recommended.
rsync -avh $GITHUB_PROJ_DIR/setup-unix ~
popd

# install Node, Python3, & misc utils
sudo apt install -y tmux python3-pip pipx python3-pynvim
n lts
npm_g install
npm_g audit fix
npm_g uninstall avn avn-nvm avn-n

# install syntax highlighter for `less`
# see: https://github.com/CoeJoder/lessfilter-pygmentize
sudo apt install -y gawk
pipx install Pygments
# if already installed:
pipx upgrade Pygments

# install neovim
# see: https://github.com/neovim/neovim/blob/master/INSTALL.md#appimage-universal-linux-package
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60

# setup neovim plugins
nvim
:UpdateRemotePlugins
:TransparentEnable

# setup X fonts
sudo apt install -y xfonts-base xfonts-scalable

# IMPORTANT: modify all the following files with your own name/email:
#   In `.gitconfig`:
#     `name` and `email` should have your own name and email.

# reboot
sudo reboot
```

### Notes

Some personal configuration/state is often contained in these configuration
files (e.g. npm logins stored in .npmrc). To prevent yourself from accidentally
adding these to the repo, try:

```sh
git update-index --assume-unchanged <path>
```

To start automatically checking for changes again:

```sh
git update-index --no-assume-unchanged <path>
```

To show all files being tracked (`assume-unchanged` files are marked with `h`,
instead of the normal `H`):

```sh
git ls-files -v
```

