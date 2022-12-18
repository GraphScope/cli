install_grape() {
  log "Building and installing libgrape-lite."

  if [[ -f "/usr/local/include/grape/grape.h" ]]; then
    log "libgrape-lite already installed, skip."
    return 0
  fi

  rm -rf ${WORKDIR}/libgrape-lite || true
  git clone --depth=1 \
      https://github.com/alibaba/libgrape-lite.git ${WORKDIR}/libgrape-lite
  pushd /tmp/libgrape-lite
  mkdir -p build
  cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX}
  make -j$(nproc)
  # TODO? may have permission issues. use sudo?
  make install
  popd
  popd
  rm -rf ${WORKDIR}/libgrape-lite
}