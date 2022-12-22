install_vineyard() {
  workdir=$1
  install_prefix=$2
  v6d_version=$3
  V6D_PREFIX="/opt/vineyard"  # fixed, related to coordinator/setup.py

  if command -v vineyardd &> /dev/null && \
     [[ $(vineyardd --version 2>&1 | awk '{print "v"$3}') == "${v6d_version}" ]]; then
    log "vineyard ${v6d_version} already installed, skip."
    return 0
  fi

  directory="v6d"
  file="${directory}.tar.gz"
  url="https://github.com/v6d-io/v6d.git"
  log "Building and installing ${directory}."

  pushd "${workdir}" || exit
  clone_if_not_exists ${directory} ${file} ${url} "${v6d_version}"
  pushd ${directory} || exit

  cmake . -DCMAKE_PREFIX_PATH="${install_prefix}" \
        -DCMAKE_INSTALL_PREFIX="${V6D_PREFIX}" \
        -DBUILD_VINEYARD_TESTS=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_VINEYARD_PYTHON_BINDINGS=ON
  make -j$(nproc)
  make install
  strip "${V6D_PREFIX}"/bin/vineyard* "${V6D_PREFIX}"/lib/libvineyard*
  python3 setup.py bdist_wheel
  python3 setup_io.py bdist_wheel
  pip3 install dist/*
  cp -rs "${V6D_PREFIX}"/* "${install_prefix}"/
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}
