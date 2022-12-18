install_openssl() {
  log "Building and installing openssl."

  pushd ${WORKDIR}
  [ ! -f OpenSSL_1_1_1h.tar.gz ] &&
    wget -q https://github.com/openssl/openssl/archive/OpenSSL_1_1_1h.tar.gz &&
    tar zxvf OpenSSL_1_1_1h.tar.gz
  pushd openssl-OpenSSL_1_1_1h
  ./config --prefix=${DEPS_PREFIX} -fPIC -shared
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/OpenSSL_1_1_1h.tar.gz ${WORKDIR}/openssl-OpenSSL_1_1_1h
}
