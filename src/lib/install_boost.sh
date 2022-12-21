install_boost() {
  log "Building and installing boost."

  pushd "${WORKDIR}" || exit
  [ ! -f boost_1_74_0.tar.gz ] &&
    wget -q https://boostorg.jfrog.io/artifactory/main/release/1.74.0/source/boost_1_74_0.tar.gz &&
    tar zxf boost_1_74_0.tar.gz
  pushd boost_1_74_0 || exit
  ./bootstrap.sh --prefix="${DEPS_PREFIX}" \
    --with-libraries=system,filesystem,context,program_options,regex,thread,random,chrono,atomic,date_time
  ./b2 install link=shared runtime-link=shared variant=release threading=multi
  popd || exit
  popd || exit
  if [ "${CLEAN_AFTER_INSTALL}" = "true" ]; then
    rm -rf "${WORKDIR}"/boost_1_74_0 "${WORKDIR}"/boost_1_74_0.tar.gz
  fi
}
