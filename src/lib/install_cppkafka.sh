install_zlib() {
  log "Building and installing zlib."

  pushd ${WORKDIR}
  [ ! -f v1.2.11.tar.gz ] &&
    wget -q https://github.com/madler/zlib/archive/v1.2.11.tar.gz
  tar zxvf v1.2.11.tar.gz
  pushd zlib-1.2.11
  cmake . -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} -DBUILD_SHARED_LIBS=ON
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/v1.2.11.tar.gz ${WORKDIR}/zlib-1.2.11

  if [ ! -f cppkafka.tar.gz ]; then
    git clone --depth 1 -b 0.4.0 --single-branch https://github.com/mfontanini/cppkafka.git
    pushd cppkafka
    git submodule update --init
  else
    tar zxvf cppkafka.tar.gz
    pushd cppkafka
  fi

  cmake . -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEPS_PREFIX} \
          -DCPPKAFKA_DISABLE_TESTS=ON  \
          -DCPPKAFKA_DISABLE_EXAMPLES=ON
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/cppkafka.tar.gz ${WORKDIR}/cppkafka
}
