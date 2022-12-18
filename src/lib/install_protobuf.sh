install_protobuf() {
  log "Building and installing ."

  pushd ${WORKDIR}
  [ ! -f protobuf-all-21.9.tar.gz ] &&
    wget -q https://github.com/protocolbuffers/protobuf/releases/download/v21.9/protobuf-all-21.9.tar.gz
  tar zxvf protobuf-all-21.9.tar.gz
  pushd protobuf-21.9
  ./configure --prefix=${DEPS_PREFIX} --enable-shared --disable-static
  make -j$(nproc)
  make install
  ldconfig
  popd
  popd
  rm -rf ${WORKDIR}/protobuf-all-21.9.tar.gz ${WORKDIR}/protobuf-21.9
}
