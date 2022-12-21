install_vineyard() {
  log "Building and installing vineyard."
  if command -v vineyardd &> /dev/null && \
     [[ "$(vineyardd --version 2>&1 | awk -F ' ' '{print $3}')" == "${V6D_VERSION}" ]]; then
    log "vineyard ${V6D_VERSION} already installed, skip."
    return 0
  fi

  rm -rf ${WORKDIR}/v6d || true
  git clone -b "${V6D_VERSION}" --depth=1 https://github.com/v6d-io/v6d.git "${WORKDIR}"/v6d
  pushd "${WORKDIR}"/v6d || exit
  git submodule update --init
  mkdir -p build
  pushd build || exit
  cmake .. -DCMAKE_PREFIX_PATH="${DEPS_PREFIX}" \
        -DCMAKE_INSTALL_PREFIX="${DEPS_PREFIX}" \
        -DBUILD_VINEYARD_TESTS=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_VINEYARD_PYTHON_BINDINGS=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit

  rm -rf "${WORKDIR}"/v6d
}