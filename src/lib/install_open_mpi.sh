install_open_mpi() {
  log "Building and installing open-mpi."

  pushd ${WORKDIR}
  [ ! -f openmpi-4.0.5.tar.gz ] &&
    wget -q https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz
  tar zxf openmpi-4.0.5.tar.gz
  pushd openmpi-4.0.5
  ./configure --enable-mpi-cxx --disable-dlopen --prefix=${MPI_PREFIX}
  make -j$(nproc)
  make install
  popd
  popd
  cp -rs ${MPI_PREFIX}/* /usr/local/
  rm -rf "${WORKDIR}"/openmpi-4.0.5 "${WORKDIR}"/openmpi-4.0.5.tar.gz
}
