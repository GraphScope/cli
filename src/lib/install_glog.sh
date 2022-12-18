install_glog() {
  log "Building and installing glog."

  pushd ${WORKDIR} &&
    [ ! -f v0.6.0.tar.gz ] &&
    wget -q https://github.com/google/glog/archive/v0.6.0.tar.gz
  tar zxvf v0.6.0.tar.gz
  pushd glog-0.6.0
  cmake . -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${DEPS_PREFIX}
  make -j$(nproc)
  make install
  popd
  popd
  rm -rf ${WORKDIR}/v0.6.0.tar.gz ${WORKDIR}/glog-0.6.0
}
