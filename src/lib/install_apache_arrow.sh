install_apache_arrow() {
  log "Building and installing apache-arrow."

  pushd ${WORKDIR}
  [ ! -f apache-arrow-9.0.0.tar.gz ] &&
    wget -q https://github.com/apache/arrow/archive/apache-arrow-9.0.0.tar.gz
  tar zxvf apache-arrow-9.0.0.tar.gz
  pushd arrow-apache-arrow-9.0.0
  cmake ./cpp \
    -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX} \
    -DARROW_COMPUTE=ON \
    -DARROW_WITH_UTF8PROC=OFF \
    -DARROW_CSV=ON \
    -DARROW_CUDA=OFF \
    -DARROW_DATASET=OFF \
    -DARROW_FILESYSTEM=ON \
    -DARROW_FLIGHT=OFF \
    -DARROW_GANDIVA=OFF \
    -DARROW_GANDIVA_JAVA=OFF \
    -DARROW_HDFS=OFF \
    -DARROW_HIVESERVER2=OFF \
    -DARROW_JSON=OFF \
    -DARROW_ORC=OFF \
    -DARROW_PARQUET=OFF \
    -DARROW_PLASMA=OFF \
    -DARROW_PLASMA_JAVA_CLIENT=OFF \
    -DARROW_PYTHON=OFF \
    -DARROW_S3=OFF \
    -DARROW_WITH_BZ2=OFF \
    -DARROW_WITH_ZLIB=OFF \
    -DARROW_WITH_LZ4=OFF \
    -DARROW_WITH_SNAPPY=OFF \
    -DARROW_WITH_ZSTD=OFF \
    -DARROW_WITH_BROTLI=OFF \
    -DARROW_IPC=ON \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_EXAMPLES=OFF \
    -DARROW_BUILD_INTEGRATION=OFF \
    -DARROW_BUILD_UTILITIES=OFF \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_ENABLE_TIMING_TESTS=OFF \
    -DARROW_FUZZING=OFF \
    -DARROW_USE_ASAN=OFF \
    -DARROW_USE_TSAN=OFF \
    -DARROW_USE_UBSAN=OFF \
    -DARROW_JEMALLOC=OFF \
    -DARROW_BUILD_SHARED=ON \
    -DARROW_BUILD_STATIC=OFF
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/arrow-apache-arrow-9.0.0 ${WORKDIR}/apache-arrow-9.0.0.tar.gz
}