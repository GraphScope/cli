install_grape() {
  log "Building and installing libgrape-lite."

  if [[ -f "/usr/local/include/grape/grape.h" ]]; then
    log "libgrape-lite already installed, skip."
    return 0
  fi

  rm -rf /tmp/libgrape-lite || true
  git clone --depth=1 \
      https://github.com/alibaba/libgrape-lite.git /tmp/libgrape-lite
  pushd /tmp/libgrape-lite
  mkdir -p build && cd build
  cmake ..
  make -j$(nproc)
  make install
  popd
  rm -fr /tmp/libgrape-lite
}