install_maven() {
  log "Downloading and installing maven."

  pushd "${WORKDIR}" || exit
  [ ! -f apache-maven-3.8.6-bin.tar.gz ] &&
    wget -q https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
  tar xzf apache-maven-3.8.6-bin.tar.gz -C "${DEPS_PREFIX}"/
  mkdir -p "${DEPS_PREFIX}"/bin
  ln -s "${DEPS_PREFIX}"/apache-maven-3.8.6/bin/mvn "${DEPS_PREFIX}"/bin/mvn
  popd || exit
  rm -rf "${WORKDIR}"/apache-maven-3.8.6-bin.tar.gz
}