# refer from https://github.com/pypa/manylinux/blob/b4884d90c984cb17f7cb4aabe3509347698d7ee7/docker/build_scripts/build_utils.sh#L26
function fetch_source {
    local file=$1
    local url=$2
    if [ -f "${file}" ]; then
        echo "${file} exists, skipping fetch"
    else
        curl -fsSL -o "${file}" "${url}"/"${file}"
        # Use sock5s proxy to download files in case download fails in normal cases
        # `host.docker.internal` is the localhost of host machine from a container's perspective.
        # See https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host
        # curl -fsSL -o ${file} ${url}/${file} || curl -x socks5h://host.docker.internal:13659 -fsSL -o ${file} ${url}/${file}
    fi
}