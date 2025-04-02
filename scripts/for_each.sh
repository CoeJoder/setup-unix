#!/bin/bash

# for_each.sh
#
# Invoke a command for each file found in the current directory.
# Example:
#   for_each -r -iregex '.*\.(flac|mp3|aac|wav|ogg|opus|m4a|mp4|webm|mkv)' bounce_loop apples

_parsed_args=$(getopt --alternative --options='r,h' --longoptions='type:,regex:,iregex:,recursive,help' \
	--name "$(basename ${BASH_SOURCE[0]})" -- "$@")
(($? != 0)) && exit 1
eval set -- "$_parsed_args"
unset _parsed_args

function usage() {
	cat >&2 <<-EOF
		Usage:
		  $(basename ${BASH_SOURCE[0]}) [options] command [args...]
		Options:
		  --type c           Match files of type c; defaults to 'f' (see \`find -type\`)
		  --regex pattern    File name matches regular expression pattern using 'posix-extended' syntax (see \`find -regex\`)
		  --iregex pattern   Like -regex, but the match is case insensitive (see \`find -iregex\`)
		  --recursive, -r    Search subfolders
		  --help, -h         Display this help and exit
	EOF
}

# parse opts
opt_type='-type f'
opt_regex=''
opt_maxdepth='-maxdepth 1'	# defaults to non-recursive
while true; do
	case "$1" in
	--type)
		opt_type="-type $2"
		shift 2
		;;
	--regex)
		opt_regex="-regextype posix-extended -regex $2"
		shift 2
		;;
	--iregex)
		opt_regex="-regextype posix-extended -iregex $2"
		shift 2
		;;
	-r | --recursive)
		opt_maxdepth=''
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		break
		;;
	*)
		echo "unknown argument: $1" >&2
		exit 1
		;;
	esac
done

# parse positional args
if [[ -z $1 ]]; then
	echo "command missing" >&2
	exit 1
fi
command="$1"
shift
args="$@"

# search for matching files
find_opts=()
[[ -n $opt_maxdepth ]] && find_opts+=($opt_maxdepth)
[[ -n $opt_type ]] && find_opts+=($opt_type)
[[ -n $opt_regex ]] && find_opts+=($opt_regex)
readarray -d '' files < <(find . "${find_opts[@]}" -print0)
if ((${#files[@]} == 0)); then
	echo "No files found." >&2
	exit 2
fi

# grammarize the text
this_each="this"
((${#files[@]} > 1)) && this_each="each"
command_suffix=" $args"
[[ -z $args ]] && command_suffix=""
msg_suffix=""
((${#files[@]} > 1)) && msg_suffix="s"

# confirm before executing
if ! yes_or_no --default-no "Found ${#files[@]} file${msg_suffix}.  Call \`$command \$file${command_suffix}\` for ${this_each} file?"; then
	exit 3
fi
for file in "${files[@]}"; do
	echo "Executing \`$command "$file"${command_suffix}\`..."
	$command "$file" $args
done
