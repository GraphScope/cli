install_vineyard() {
  log "Building and installing vineyard."
  if command -v /usr/local/bin/vineyardd &> /dev/null && \
     [[ "$(/usr/local/bin/vineyardd --version 2>&1 | awk -F ' ' '{print $3}')" == "${V6D_VERSION}" ]]; then
    log "vineyard ${V6D_VERSION} already installed, skip."
    return 0
  fi

  rm -rf /tmp/v6d || true
  git clone --depth=1 https://github.com/v6d-io/v6d.git /tmp/v6d
  pushd /tmp/v6d
  git submodule update --init
  mkdir -p build && pushd build
  cmake .. -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} \
           -DBUILD_SHARED_LIBS=ON \
           -DBUILD_VINEYARD_TESTS=OFF
  make -j$(nproc)
  make install && popd
  popd

  rm -fr /tmp/v6d
}