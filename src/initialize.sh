## Code here runs inside the initialize() function
## Use it for anything that you need to run before any other function, like
## setting environment variables:
## CONFIG_FILE=settings.ini
##
## Feel free to empty (but not delete) this file.


bash_source_dir="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"


if [ "${GRAPHSCOPE_ENV:-dev}" == "dev" ]; then
    log "Setting the environment for development.\n"
    warning "GRAPHSCOPE_HOME will set to source root (${bash_source_dir}) for development."
    warning "To use you assigned GRAPHSCOPE_HOME, export GRAPHSCOPE_ENV=prod.\n"
    if [[ -z "${GRAPHSCOPE_HOME}" ]]; then
        export GRAPHSCOPE_HOME="${bash_source_dir}"
    fi
elif [ "${GRAPHSCOPE_ENV:-dev}" == "prod" ]; then
    log "Setting the environment for production"
else
    err "Invalid GRAPHSCOPE_ENV. (should be dev or prod)"
    exit 1
fi

log "Read the env: GRAPHSCOPE_HOME=${GRAPHSCOPE_HOME:-}"
