install_cppkafka() {
  log "Building and installing cppkafka."

  pushd "${WORKDIR}" || exit
  if [ ! -f cppkafka.tar.gz ]; then
    git clone --depth 1 -b 0.4.0 --single-branch https://github.com/mfontanini/cppkafka.git
    pushd cppkafka || exit
    git submodule update --init
  else
    tar zxf cppkafka.tar.gz
    pushd cppkafka || exit
  fi

  cmake . -DCMAKE_INSTALL_PREFIX="${DEPS_PREFIX}" \
          -DCMAKE_PREFIX_PATH="${DEPS_PREFIX}" \
          -DCPPKAFKA_DISABLE_TESTS=ON  \
          -DCPPKAFKA_DISABLE_EXAMPLES=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  rm -rf "${WORKDIR}"/cppkafka.tar.gz "${WORKDIR}"/cppkafka
}
