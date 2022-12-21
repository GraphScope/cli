install_cmake() {
  log "Building and installing cmake."
  ARCH=$(uname -m)
  pushd ${WORKDIR}
  [ ! -f cmake-3.24.3-linux-${ARCH}.sh ] &&
    wget -q https://github.com/Kitware/CMake/releases/download/v3.24.3/cmake-3.24.3-linux-${ARCH}.sh
  bash cmake-3.24.3-linux-${ARCH}.sh --prefix="${DEPS_PREFIX}" --skip-license
  popd
  rm -rf "${WORKDIR}"/cmake-3.24.3-linux-*.sh
}
