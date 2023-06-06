## Code here runs inside the initialize() function
## Use it for anything that you need to run before any other function, like
## setting environment variables:
## CONFIG_FILE=settings.ini
##
## Feel free to empty (but not delete) this file.

bash_source_dir="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"

if [ -f "$HOME/.graphscope_env" ]; then
	source $HOME/.graphscope_env
fi

log "Read the env: GRAPHSCOPE_HOME=${GRAPHSCOPE_HOME:-}"
