install_zlib() {
  log "Building and installing zlib."

  pushd ${WORKDIR}
  [ ! -f v1.2.11.tar.gz ] &&
    wget -q https://github.com/madler/zlib/archive/v1.2.11.tar.gz
  tar zxvf v1.2.11.tar.gz
  pushd zlib-1.2.11
  cmake . -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEPS_PREFIX} \
          -DBUILD_SHARED_LIBS=ON
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/v1.2.11.tar.gz ${WORKDIR}/zlib-1.2.11
}
