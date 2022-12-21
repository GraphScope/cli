install_grpc() {
  log "Building and installing grpc."
  pushd ${WORKDIR}
  if [ ! -f grpc.tar.gz ]; then
    git clone --depth 1 --branch v1.49.1 https://github.com/grpc/grpc.git
    pushd grpc
    git submodule update --init
  else
    tar zxvf grpc.tar.gz
    pushd grpc
  fi
  cmake . -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} \
          -DCMAKE_PREFIX_PATH=${DEPS_PREFIX} \
          -DBUILD_SHARED_LIBS=ON \
          -DgRPC_INSTALL=ON \
          -DgRPC_BUILD_TESTS=OFF \
          -DgRPC_BUILD_CSHARP_EXT=OFF \
          -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
          -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
          -DgRPC_BACKWARDS_COMPATIBILITY_MODE=ON \
          -DgRPC_PROTOBUF_PROVIDER=package \
          -DgRPC_ZLIB_PROVIDER=package \
          -DgRPC_SSL_PROVIDER=package \
          -DOPENSSL_ROOT_DIR=${DEPS_PREFIX} \
          -DCMAKE_CXX_FLAGS="-fpermissive" \
          -DPNG_ARM_NEON_OPT=0
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/grpc
}
