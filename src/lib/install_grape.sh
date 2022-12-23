install_grape() {
  workdir=$1
  install_prefix=$2

  if [[ -f "${install_prefix}/include/grape/grape.h" ]]; then
    log "libgrape-lite already installed, skip."
    return 0
  fi
  directory="libgrape-lite"
  file="${directory}.tar.gz"
  url="https://github.com/alibaba/libgrape-lite.git"
  branch="master"
  log "Building and installing ${directory}."

  pushd "${workdir}" || exit
  clone_if_not_exists ${directory} ${file} ${url} ${branch}
  pushd ${directory} || exit

  cmake . -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
          -DCMAKE_PREFIX_PATH="${install_prefix}"
  make -j$(nproc)
  make install
  strip "${install_prefix}/bin/run_app"
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}
