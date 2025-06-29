# projects directory
export PROJECTS_DIR="$HOME/projects"
if [[ ! -d $PROJECTS_DIR ]]; then
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

# common regex e.g. used with `find`
REGEX_TYPE='posix-extended'
REGEX_AUDIO='.*\.(flac|mp3|aac|wav|ogg|opus|m4a)'
REGEX_VIDEO='.*\.(mp4|webm|mkv)'
REGEX_AV='.*\.(flac|mp3|aac|wav|ogg|opus|m4a|mp4|webm|mkv)'

# ensure agent is running
# see: https://stackoverflow.com/a/48509425/159570
ssh-add -l &>/dev/null
if [ "$?" == 2 ]; then
	# Could not open a connection to your authentication agent.

	# Load stored agent connection info.
	test -r ~/.ssh-agent &&
		eval "$(<~/.ssh-agent)" >/dev/null

	ssh-add -l &>/dev/null
	if [ "$?" == 2 ]; then
		# Start agent and store agent connection info.
		(
			umask 066
			ssh-agent >~/.ssh-agent
		)
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
	tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' |
		xargs -n 1 tmux kill-session -t || echo No sessions to kill
}

# print the external IP address to stdout
whatismyip() {
	echo "$(curl -kLs https://ipinfo.io/ip)"
}

# `read` but allows a default value
function read_with_default() {
	if [[ $# -lt 3 ]]; then
		echo "usage: read_with_default prompt default_val outvar" >&2
		return 1
	fi
	local prompt="$1" default_val="$2" outvar="$3"
	local _val
	# cursor: save
	echo -en "${prompt}\e[s"
	read _val
	if [[ -z $_val ]]; then
		_val="$default_val"
		# cursor: 1-up, load
		echo -e "\e[1A\e[u${_val}"
	fi
	printf -v $outvar "$_val"
}

# activate & mount a LUKS container
function luks_open() ( # subshell function
	set -Eeuo pipefail # bash strict-mode

	blkid_output=$(blkid -t TYPE=crypto_LUKS -lo export)
	if [[ -z $blkid_output ]]; then
		echo "no LUKS container found" >&2
		exit 1
	fi
	source <(echo "$blkid_output")
	if [[ -z $DEVNAME ]]; then
		echo "expected DEVNAME to be non-empty" >&2
		exit 1
	fi
	read_with_default "LUKS container ($DEVNAME): " "$DEVNAME" src_container
	if [[ -z $src_container ]]; then
		echo "no container specified" >&2
		exit 1
	fi

	default_val="skyhawk"
	read_with_default "Name ($default_val): " "$default_val" name

	default_val="/mnt/$name"
	read_with_default "Mount point ($default_val): " "$default_val" mount_point

	default_val="/dev/mapper/$name"
	read_with_default "Mapped device ($default_val): " "$default_val" mapped_device

	# activate container and mount it
	sudo cryptsetup open "$src_container" "$name"
	sudo mount "$mapped_device" "$mount_point"
)

# deactivate & unmount a LUKS container
function luks_close() ( # subshell function
	set -Eeuo pipefail # bash strict-mode

	blkid_output=$(blkid -t TYPE=crypto_LUKS -lo export)
	if [[ -z $blkid_output ]]; then
		echo "no LUKS container found" >&2
		exit 1
	fi
	source <(echo "$blkid_output")
	if [[ -z $DEVNAME ]]; then
		echo "expected DEVNAME to be non-empty" >&2
		exit 1
	fi
	read_with_default "LUKS container ($DEVNAME): " "$DEVNAME" src_container
	if [[ -z $src_container ]]; then
		echo "no container specified" >&2
		exit 1
	fi

	default_val="skyhawk"
	read_with_default "Name ($default_val): " "$default_val" name

	default_val="/mnt/$name"
	read_with_default "Mount point ($default_val): " "$default_val" mount_point

	# unmount container and deactivate it
	sudo umount "$mount_point"
	sudo cryptsetup close "$name"
	sudo eject "$src_container"
)

# in-place shell selection list
# source: https://askubuntu.com/a/1386907
# (with minor syntax changes to fix vscode syntax highlighting)
function choose_from_menu() {
	local prompt="$1" outvar="$2"
	shift
	shift
	local options=("$@") cur=0 count=${#options[@]} index=0
	local esc=$(echo -en "\e") # cache ESC as test doesn't allow esc codes
	printf "$prompt\n"
	while true; do
		# list all options (option list is zero-based)
		index=0
		for o in "${options[@]}"; do
			if [ "$index" == "$cur" ]; then
				echo -e " >\e[7m$o\e[0m" # mark & highlight the current option
			else
				echo "  $o"
			fi
			index=$(($index + 1))
		done
		read -s -n3 key                 # wait for user to key in arrows or ENTER
		if [[ $key == "$esc[A" ]]; then # up arrow
			cur=$(($cur - 1))
			[ "$cur" -lt 0 ] && cur=0
		elif [[ $key == "$esc[B" ]]; then # down arrow
			cur=$(($cur + 1))
			[ "$cur" -ge $count ] && cur=$(($count - 1))
		elif [[ $key == "" ]]; then # nothing, i.e the read delimiter - ENTER
			break
		fi
		echo -en "\e[${count}A" # go up to the beginning to re-render
	done
	# export the selection to the requested output variable
	printf -v $outvar "${options[$cur]}"
}

# escapes arbitrary strings for use in sed regex
# source: https://stackoverflow.com/a/29613573/159570
function escape_sed_regex() { sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n'; }

# given a gitssh endpoint, clones the repo according to gitdir/ssh-user mappings
function gitssh_clone() {
	# NOTE current impl assumes particular structure of config file;
	# could move to python and parse with GitPython or ConfigParser
	local git_config="$HOME/.config/git/config"
	if [[ ! -f $git_config ]]; then
		echo "$git_config not found" >&2
		return 1
	fi
	if [[ $# -lt 1 ]]; then
		echo "usage: gitssh-clone [git-clone_options] gitssh-endpoint" >&2
		echo "       gitssh-clone --dry-run gitssh-endpoint" >&2
		return 1
	fi
	if [[ $# -gt 1 ]]; then
		local git_options="${@:1:$#-1}"
	fi
	local endpoint="${@: -1}"
	# parse the endpoint argument
	local regex='git@([^:]*):([^/]*)/(.*?)\.git'
	if [[ ! $endpoint =~ $regex ]]; then
		echo "unrecognized gitssh-endpoint format" >&2
		return 1
	fi
	local site=${BASH_REMATCH[1]}
	local remote_gituser=${BASH_REMATCH[2]}
	local project=${BASH_REMATCH[3]}
	local escaped_site=$(escape_sed_regex "$site")
	local -A users_to_dirs
	local _cur_user
	local _i=0
	while read -r _line; do
		if [[ $((_i % 2)) -eq 0 ]]; then
			_cur_user=$_line
		else
			users_to_dirs[$_cur_user]=$_line
		fi
		((_i++))
	done < <(sed -n \
		-re "s|~|$HOME|" \
		-re '/\[includeIf "gitdir:/{s|\[.*:(.*)/\**".*|\1|;h;d;n}' \
		-re "\|path\s*=.*/\.config/git/.*-$escaped_site\.config|{s|.*/(.*)-$escaped_site\.config|\1|p;x;p}" \
		"$git_config")
	if ((${#users_to_dirs[@]} == 0)); then
		echo "no $site users found in $git_config" >&2
		return 1
	fi
	local local_gituser
	choose_from_menu "Local git user:" local_gituser "${!users_to_dirs[@]}"
	if [[ -z $local_gituser ]]; then
		echo "invalid username" >&2
		return 1
	fi
	new_endpoint="${site}_$local_gituser:$remote_gituser/$project.git"
	dest_dir="${users_to_dirs[$local_gituser]}/$project"
	if [[ $git_options == '--dry-run' ]]; then
		printf "%s\n%s\n" "Repository: $new_endpoint" "Directory: $dest_dir"
	else
		# clone into the mapped directory using the rewritten endpoint
		echo -e "Site: $site\nProject: $remote_gituser/$project"
		read -p "Clone into $dest_dir? (y/N): " confirm &&
			[[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return 1
		git clone $git_options "$new_endpoint" "$dest_dir" ||
			return
		echo "pushd..."
		pushd "$dest_dir" >/dev/null
	fi
}

# terminal-only, url-aware alternative to `pygmentize` with enhanced lexer guessing
function pygterminize() {
	local pygments_python="$HOME/.local/share/pipx/venvs/pygments/bin/python"
	local pygterminize="$HOME/scripts/pygterminize.py"
	if [[ ! -f $pygments_python ]]; then
		echo "not found: $pygments_python" >&2
		return 1
	fi
	if [[ ! -f $pygterminize ]]; then
		echo "not found: $pygterminize" >&2
		return 1
	fi
	"$pygments_python" "$pygterminize" $@
}

# fetch and pygmentize a URL document to stdout
function pyget() {
	if ! type -P wget >/dev/null 2>&1; then
		echo "command 'wget' not found" >&2
		return 1
	fi
	if [[ $# -ne 1 ]]; then
		echo "usage: pyget url" >&2
		return 1
	fi
	local url="$1"
	(
		set -euo pipefail
		wget -q --show-progress -O - "$url" | pygterminize -u "$url"
	)
}

# fetch and pygmentize a URL document to less
function lessget() {
	if [[ $# -lt 1 ]]; then
		echo "usage: lessget [less_options] url" >&2
		return 1
	fi
	if [[ $# -gt 1 ]]; then
		local less_options="${@:1:$#-1}"
	fi
	local url="${@: -1}"
	# use a temp file to handle large docs
	(
		set -eo pipefail
		tempfile=$(mktemp)
		trap "rm -f ${tempfile@Q}" EXIT
		pyget "$url" >"$tempfile"
		less $less_options "$tempfile"
	)
}

# get the most recent file in the tree
# source: https://stackoverflow.com/a/38996701/159570
function get_latest_file() {
	local dir=${1:-.}
	readarray -t -d '' files < <(LC_ALL=C find "$dir" -name . -o -name '.*' \
		-prune -o -type f -printf '%T@/%p\0' | sort -rzn | cut -zd/ -f2-)
	((${#files[@]} > 0)) && printf '%s\n' "${files[0]}"
}

# copy to clipboard the most recent receipt path as a spreadsheet hyperlink
function get_receipt() {
	local receipts_dir="$HOME/Documents/Receipts"
	local latest_file=$(get_latest_file "$receipts_dir")
	local full_path=$(realpath "$latest_file")
	local base_name=$(basename "$latest_file")
	local output="=HYPERLINK(\"${full_path}\", \"${base_name}\")"
	printf "%s" "$output" | xclip -selection clipboard
	echo "Copied to clipboard: $output"
}

# copy to clipboard a spreadsheet hyperlink constructed in the shell
function to_hyperlink() {
	if [[ $# -ne 2 ]]; then
		echo "usage: to_hyperlink path name"
		return 1
	fi
	local path="$1" name="$2"
	local output="=HYPERLINK(\"${path}\", \"${name}\")"
	printf "%s" "$output" | xclip -selection clipboard
	echo "Copied to clipboard: $output"
}

# launch media player with all media files in the given directory tree added to the playlist
function play_music_shuffled() {
	local music_dirs chosen_dir
	local root_dir="$HOME/Music"
	if [[ $# -gt 0 ]]; then
		root_dir="$1"
		if [[ ! -d $root_dir ]]; then
			echo "Directory not found: $root_dir" >&2
			return 1
		fi
	fi
	readarray -t music_dirs < <(find "$root_dir" -maxdepth 1 -type d -printf '%p\n')
	choose_from_menu "Make your selection:" chosen_dir "${music_dirs[@]}"
	readarray -d '' chosen_files < <(find "$chosen_dir" -regextype "$REGEX_TYPE" -iregex "$REGEX_AV" -type f -print0)
	# TODO passing files as expanded-array doesn't shuffle, but globbing does
	(celluloid --mpv-shuffle --mpv-fullscreen "${chosen_files[@]}" &>/dev/null &)
}

# launch media player for 1337 h4cker jamz
function robot_ears() {
	play_music_shuffled "$HOME/Music/Programming Music"
}

# simple codium launcher which caches path argument
function code() {
	local last_proj_file="$HOME/.last_codium_project"
	local codium_arg=''
	if [[ $# -eq 0 ]]; then
		if [[ -f $last_proj_file ]]; then
			codium_arg="$(<"$last_proj_file")"
		fi
	else
		codium_arg="$(realpath "$1")"
		printf '%s' "$codium_arg" >"$last_proj_file"
	fi
	[[ -n $codium_arg ]] && pushd "$codium_arg" &>/dev/null
	codium "$codium_arg"
}

# create a bounce-loop of a media file with filename like `foo-bounced.bar`
function bounce_loop() {
	if (($# != 1 && $# != 2)); then
		echo "usage: bounce_loop input [numLoops=0]" >&2
		return 1
	fi
	local input="$(realpath "$1")"
	shift
	local numLoops="${1:-0}"
	local framerate_fraction=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nw=1:nk=1 "$input")
	local framerate="$(python3 -c "print(round(${framerate_fraction}))")"
	local duration="$(ffprobe -i "$input" -show_entries format=duration -v quiet -of csv="p=0")"
	local bouncelen="$(python3 -c "print(round($framerate * (2 * $duration)))")"
	local parent="$(dirname "$input")"
	local basename="$(basename "$input")"
	local stem="${basename%%.*}"
	local ext="${basename#*.}"
	local output="$parent/$stem-bounced.$ext"
	ffmpeg -i "$input" -filter_complex "[0]reverse[r];[0][r]concat,loop=$numLoops:$bouncelen,setpts=N/$framerate/TB" "$output"
	echo "Output: $output"
}

# invoke command for each file found in current dir like so: `command file args`
function for_each() (		# subshell
	local for_each_sh="$HOME/scripts/for_each.sh"
	if [[ ! -x $for_each_sh ]]; then
		echo "executable not found: $for_each_sh" >&2
		return 1
	fi
	source "$for_each_sh" "$@"
)

# concatenate .mp4 files in the current directory by name substring
function ffconcat() {
	if (($# != 1)); then
		echo "usage: ffconcat name" >&2
		return 1
	fi
	local name="$1"
	ffmpeg -f concat -safe 0 -i <(for f in *$name*.mp4; do echo "file '$PWD/$f'"; done) -c copy "${name}_$(date +%Y%m%d_%H%M%S).mp4"
}

# repeat call to `yt-dlp` until consecutive failures reach timeout
function repeat_yt_dlp() {
	if ! type -P yt-dlp >/dev/null 2>&1; then
		echo "command 'yt-dlp' not found" >&2
		return 1
	fi
	if (($# < 1 || $# > 5)); then
		echo "usage: repeat_yt_dlp url [timeout=300] [delay=3] [initTimeout=300] [initDelay=3]" >&2
		return 1
	fi
	local url="$1"
	shift
	local timeout="${1:-300}"
	shift
	local delay="${1:-3}"
	shift
	local initTimeout="${1:-300}"
	shift
	local initDelay="${1:-3}"
	local failcount=0
	local failmax=$(python3 -c "print(round($timeout / $delay))")
	local initFailcount=0
	local initFailmax=$(python3 -c "print(round($initTimeout / $initDelay))")
	# initial polling: loop until hit, return if timeout on no-hits
	while ! yt-dlp "$url"; do
		((++initFailcount >= initFailmax)) && return
		sleep $initDelay
	done
	# subsequent polling: loop forever, break if timeout on consecutive no-hits
	while true; do
		if ! yt-dlp "$url"; then
			((++failcount >= failmax)) && break
		else
			failcount=0
		fi
		sleep $delay
	done
}

# yes-or-no prompt
# 'no' is always falsey (returns 1)
# source: https://github.com/CoeJoder/ethereum-node/blob/master/src/common.sh
function yes_or_no() {
	local confirm
	if [[ $# -ne 2 || ($1 != '--default-yes' && $1 != '--default-no') ]]; then
		echo 'usage: yes_or_no {--default-yes|--default-no} prompt' >&2
		return 2
	fi
	local default_opt="$1" prompt="$2" confirm
	if [[ $default_opt == '--default-yes' ]]; then
		read -p "$prompt (Y/n): " confirm
		if [[ $confirm == [nN] || $confirm == [nN][oO] ]]; then
			return 1
		fi
	else
		read -p "$prompt (y/N): " confirm
		if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
			return 1
		fi
	fi
}

# set title of terminal tab (default: current tab)
function set_tab_title() {
	if (($# < 1)); then
		echo 'usage: set_tab_title title [tab-id]' >&2
		return 2
	fi
	local title="$1" tab cur_pane
	shift
	if (($# > 0)); then
		tab="$1"
	else
		# find the current tab id
		cur_pane="$(wezterm cli list-clients --format=json | jq -r '.[] |
			.focused_pane_id')" || return
		tab="$(wezterm cli list --format=json | jq --argjson cur_pane "$cur_pane" -r '.[] |
			select(.pane_id==$cur_pane) |
			.tab_id')" || return
	fi
	wezterm cli set-tab-title --tab-id "$tab" "$title" || return
}

# start tmux with the current environment
if [ "$TMUX" = "" ] && [ "$SKIP_TMUX" != 0 ]; then tmux -L default; fi
