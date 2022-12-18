install_gflags() {
  log "Building and installing gflags."

  pushd ${WORKDIR}
  [ ! -f v2.2.2.tar.gz ] &&
    wget -q https://github.com/gflags/gflags/archive/v2.2.2.tar.gz
  tar zxvf v2.2.2.tar.gz
  pushd gflags-2.2.2
  cmake . -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX}
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/v2.2.2.tar.gz ${WORKDIR}/gflags-2.2.2
}
