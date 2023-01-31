install_vineyard() {
  workdir=$1
  install_prefix=$2
  v6d_version=$3
  jobs=${4:-4} # $4:default=4
  V6D_PREFIX="/opt/vineyard"  # fixed, related to coordinator/setup.py

  if [[ -f "${V6D_PREFIX}/include/vineyard/client/client.h" ]]; then
    log "vineyard already installed, skip."
    return 0
  fi

  directory="v6d"
  file="${directory}-${v6d_version}.tar.gz"
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  if [[ "${v6d_version}" == "v"* ]]; then
    url="https://github.com/v6d-io/v6d.git"
    clone_if_not_exists ${directory} "${file}" "${url}" "${v6d_version}"
  else
    url="https://github.com/v6d-io/v6d/releases/download/${v6d_version}"
    cn_url=$(maybe_set_to_cn_url "${url}")
    status=$(curl --head --silent "${cn_url}"/"${file}" | head -n 1)
    if echo "${status}" | grep -q 404; then
      download_tar_and_untar_if_not_exists ${directory} "${file}" "${url}"
    else
      download_tar_and_untar_if_not_exists ${directory} "${file}" "${cn_url}"
    fi

  fi
  pushd ${directory} || exit

  cmake . -DCMAKE_PREFIX_PATH="${install_prefix}" \
        -DCMAKE_INSTALL_PREFIX="${V6D_PREFIX}" \
        -DBUILD_VINEYARD_TESTS=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_VINEYARD_PYTHON_BINDINGS=ON
  make -j"${jobs}"
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
