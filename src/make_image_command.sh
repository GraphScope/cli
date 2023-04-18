echo "# this file is located in 'src/make_image_command.sh'"
echo "# code for 'gs make-image' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

#     allowed: [all, graphscope-dev, coordinator, analytical, analytical-java, interactive, interactive-frontend, interactive-executor, learning, vineyard-dev, vineyard-runtime]

component=${args[component]}

log "Making image ${component}"

registry=${args[--registry]}
tag=${args[--tag]}

export INSTALL_PREFIX=${install_prefix}

make_all() {
    cd k8s
    make all
}

make_graphscope-dev() {
    cd k8s
    make graphscope-dev REGISTRY=${registry} VERSION=${tag}
}

make_analytical() {
    cd k8s
    make analytical REGISTRY=${registry} VERSION=${tag}
}

make_interactive() {
    cd k8s
    make interactive REGISTRY=${registry} VERSION=${tag}
}

make_interactive-frontend() {
    cd k8s
    make interactive-frontend REGISTRY=${registry} VERSION=${tag}
}

make_interactive-executor() {
    cd k8s
    make interactive-executor REGISTRY=${registry} VERSION=${tag}
}

make_learning() {
    cd k8s
    make learning REGISTRY=${registry} VERSION=${tag}
}


make_coordinator() {
    cd k8s
    make coordinator REGISTRY=${registry} VERSION=${tag}
}

make_vineyard-dev() {
    cd k8s
    make vineyard-dev REGISTRY=${registry} VERSION=${tag}
}

make_vineyard-runtime() {
    cd k8s
    make vineyard-runtime REGISTRY=${registry} VERSION=${tag}
}

make_${component}