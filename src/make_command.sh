echo "# this file is located in 'src/make_command.sh'"
echo "# code for 'gs make' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

component=${args[component]}

log "Making component ${component}"

install_prefix=${args[--install-prefix]}

export INSTALL_PREFIX=${install_prefix}

make_all() {
    make all
}

make_install() {
    make install
}

make_analytical() {
    make analytical
}

make_interactive() {
    make interactive
}

make_learning() {
    make learning
}

make_analytical-install() {
    make analytical-install INSTALL_PREFIX=${install_prefix}
}

make_interactive-install() {
    make interactive-install INSTALL_PREFIX=${install_prefix}
}

make_learning-install() {
    make learning-install INSTALL_PREFIX=${install_prefix}
}

make_client() {
    make client
}

make_coordinator() {
    make coordinator
}

make_analytical-java() {
    make analytical-java
}

make_analytical-java-install() {
    make analytical-java-install INSTALL_PREFIX=${install_prefix}
}

make_clean() {
    make clean
}

make_${component}