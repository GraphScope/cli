install_cmake() {
  workdir=$1
  install_prefix=$2

  ARCH=$(uname -m)
  file="cmake-3.24.3-linux-${ARCH}.sh"
  log "Building and installing ${file}."
  pushd "${workdir}" || exit

  url="https://github.com/Kitware/CMake/releases/download/v3.24.3"
  url=$(maybe_set_to_cn_url ${url})
  [ ! -f "${file}" ] &&
    fetch_source "${file}" "${url}"
  bash "${file}" --prefix="${install_prefix}" --skip-license
  popd || exit
  cleanup_files "${workdir}/${file}"
}

install_open_mpi() {
  workdir=$1
  install_prefix=$2
  MPI_PREFIX="/opt/openmpi"  # fixed, related to coordinator/setup.py

  directory="openmpi-4.0.5"
  file="openmpi-4.0.5.tar.gz"
  url="https://download.open-mpi.org/release/open-mpi/v4.0"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  ./configure --enable-mpi-cxx --disable-dlopen --prefix=${MPI_PREFIX}
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cp -rs ${MPI_PREFIX}/* "${install_prefix}"
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_gflags() {
  workdir=$1
  install_prefix=$2

  directory="gflags-2.2.2"
  file="v2.2.2.tar.gz"
  url="https://github.com/gflags/gflags/archive"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing gflags-2.2.2."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  cmake . -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
          -DCMAKE_PREFIX_PATH="${install_prefix}" \
          -DBUILD_SHARED_LIBS=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_glog() {
  workdir=$1
  install_prefix=$2

  directory="glog-0.6.0"
  file="v0.6.0.tar.gz"
  url="https://github.com/google/glog/archive"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  cmake . -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
          -DCMAKE_PREFIX_PATH="${install_prefix}" \
          -DBUILD_SHARED_LIBS=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_apache_arrow() {
  workdir=$1
  install_prefix=$2

  directory="arrow-apache-arrow-9.0.0"
  file="apache-arrow-9.0.0.tar.gz"
  url="https://github.com/apache/arrow/archive"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  cmake ./cpp \
    -DCMAKE_PREFIX_PATH="${install_prefix}" \
    -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
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
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_boost() {
  workdir=$1
  install_prefix=$2

  directory="boost_1_74_0"
  file="${directory}.tar.gz"
  url="https://boostorg.jfrog.io/artifactory/main/release/1.74.0/source"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  ./bootstrap.sh --prefix="${install_prefix}" \
    --with-libraries=system,filesystem,context,program_options,regex,thread,random,chrono,atomic,date_time
  ./b2 install link=shared runtime-link=shared variant=release threading=multi
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_openssl() {
  workdir=$1
  install_prefix=$2

  directory="openssl-OpenSSL_1_1_1h"
  file="OpenSSL_1_1_1h.tar.gz"
  url="https://github.com/openssl/openssl/archive"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  ./config --prefix="${install_prefix}" -fPIC -shared
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_zlib() {
  workdir=$1
  install_prefix=$2

  directory="zlib-1.2.11"
  file="v1.2.11.tar.gz"
  url="https://github.com/madler/zlib/archive"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  cmake . -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
          -DCMAKE_PREFIX_PATH="${install_prefix}" \
          -DBUILD_SHARED_LIBS=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_protobuf() {
  workdir=$1
  install_prefix=$2

  directory="protobuf-21.9"
  file="protobuf-all-21.9.tar.gz"
  url="https://github.com/protocolbuffers/protobuf/releases/download/v21.9"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  ./configure --prefix="${install_prefix}" --enable-shared --disable-static
  make -j$(nproc)
  make install
  ldconfig
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_grpc() {
  workdir=$1
  install_prefix=$2

  directory="grpc"
  file="${directory}.tar.gz"
  url="https://github.com/grpc/grpc.git"
  url=$(maybe_set_to_cn_url ${url})
  branch="v1.49.1"
  log "Building and installing ${directory}."

  pushd "${workdir}" || exit
  clone_if_not_exists ${directory} ${file} "${url}" ${branch}
  pushd ${directory} || exit

  cmake . -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
          -DCMAKE_PREFIX_PATH="${install_prefix}" \
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
          -DOPENSSL_ROOT_DIR="${install_prefix}" \
          -DCMAKE_CXX_FLAGS="-fpermissive" \
          -DPNG_ARM_NEON_OPT=0
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_cppkafka() {
  workdir=$1
  install_prefix=$2

  directory="cppkafka-0.4.0"
  file="0.4.0.tar.gz"
  url="https://github.com/mfontanini/cppkafka/archive/refs/tags"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  pushd ${directory} || exit

  cmake . -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
          -DCMAKE_PREFIX_PATH="${install_prefix}" \
          -DCPPKAFKA_DISABLE_TESTS=ON  \
          -DCPPKAFKA_DISABLE_EXAMPLES=ON
  make -j$(nproc)
  make install
  popd || exit
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}

install_maven() {
  workdir=$1
  install_prefix=$2

  directory="apache-maven-3.8.6"
  file="apache-maven-3.8.6-bin.tar.gz"
  url="https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries"
  url=$(maybe_set_to_cn_url ${url})
  log "Building and installing ${directory}."
  pushd "${workdir}" || exit
  download_tar_and_untar_if_not_exists ${directory} ${file} "${url}"
  cp -r ${directory} "${install_prefix}"/

  mkdir -p "${install_prefix}"/bin
  ln -s "${install_prefix}/${directory}/bin/mvn" "${install_prefix}/bin/mvn"
  popd || exit
  cleanup_files "${workdir}/${directory}" "${workdir}/${file}"
}
