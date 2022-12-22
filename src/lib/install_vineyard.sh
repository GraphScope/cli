install_vineyard() {
  workdir=$1
  install_prefix=$2

  if command -v vineyardd &> /dev/null && \
     [[ $(vineyardd --version 2>&1 | awk '{print "v"$3}') == "${V6D_VERSION}" ]]; then
    log "vineyard ${V6D_VERSION} already installed, skip."
    return 0
  fi

  directory="v6d"
  file="${directory}.tar.gz"
  url="https://github.com/v6d-io/v6d.git"
  branch="v0.11.2"
  log "Building and installing ${directory}."

  pushd "${workdir}" || exit
  clone_if_not_exists ${directory} ${file} ${url} "${branch}"
  pushd ${directory} || exit

  cmake . -DCMAKE_PREFIX_PATH="${install_prefix}" \
        -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
        -DBUILD_VINEYARD_TESTS=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_VINEYARD_PYTHON_BINDINGS=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}
