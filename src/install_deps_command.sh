inspect_args
type=${args[--type]}
cn=${args[--cn]}

readonly OS=$(get_os_version)
readonly OS_PLATFORM=${OS%-*}
readonly OS_VERSION=${OS#*-}

echo "$(green_bold "Installing ${type} dependencies for GraphScope on ${OS}...")"

if [[ -n $cn ]]; then
    echo "$(green "Set to speed up downloading for CN locations.")"
    # export some mirror locations for CN, e.g., brew/docker... 
fi

install_deps_for_dev(){
    echo "TODO"
    # install_deps for development on local
}


install_deps_for_client(){
    echo "TODO"
    # install python..  
}