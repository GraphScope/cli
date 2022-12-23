inspect_args

type=${args[type]}
# from-local=${args[--from-local]}
cn=${args[--cn]}
install_prefix=${args[--prefix]}
deps_prefix=${args[--deps-prefix]}

only_grape_v6d=${args[--only-grape-v6d]}
no_grape_v6d=${args[--no-grape-v6d]}

v6d_version=${args[--v6d-version]}

if [[ $(id -u) -ne 0 ]]; then
  warning "Not running as root."
else
  warning "Please note that I am running as root."
fi

readonly OS=$(get_os_version)
readonly OS_PLATFORM=${OS%-*}
readonly OS_VERSION=${OS#*-}

readonly OUTPUT_ENV_FILE="${HOME}/.graphscope_env"

BASIC_PACKAGES_TO_INSTALL=

log "Installing ${type} dependencies for GraphScope on ${OS}..."

if [[ -n ${cn} ]]; then
  log "Set to speed up downloading for CN locations."
  # export some mirror locations for CN, e.g., brew/docker...
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
  export GRAPHSCOPE_DOWNLOAD_FROM_CN="true"
fi

if [[ -n ${only_grape_v6d} ]]; then
  log "Only install libgrape-lite and vineyard."
  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    install_grape_vineyard_macos
  else
    install_grape_vineyard_linux
  fi
  exit 0
fi

check_os_compatibility() {
  if [[ "${OS_PLATFORM}" != *"Ubuntu"* && "${OS_PLATFORM}" != *"CentOS"* && "${OS_PLATFORM}" != *"Darwin"* ]]; then
    err "The script is only support platforms of Ubuntu/CentOS/macOS"
    exit 1
  fi

  if [[ "${OS_PLATFORM}" == *"Ubuntu"* && "${OS_VERSION:0:2}" -lt "20" ]]; then
    err "The version of Ubuntu is ${OS_VERSION}. This script requires Ubuntu 20 or greater."
    exit 1
  fi

  if [[ "${OS_PLATFORM}" == *"CentOS"* && "${OS_VERSION}" -lt "7" ]]; then
    err "The version of CentOS is ${OS_VERSION}. This script requires CentOS 8 or greater."
    exit 1
  fi

  log "Running on ${OS_PLATFORM} ${OS_VERSION}"
}

init_basic_packages() {
  if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
    BASIC_PACKAGES_TO_INSTALL=(
      wget
      git
      cmake
      build-essential
      lsb-release
      libopenmpi-dev
      libgflags-dev
      libgoogle-glog-dev
      libboost-all-dev
      libprotobuf-dev
      libgrpc++-dev
      protobuf-compiler-grpc
      python3-pip
      libunwind-dev
      rapidjson-dev
      libmsgpack-dev
      librdkafka-dev
    )
  elif [[ "${OS_PLATFORM}" == *"CentOS"* ]]; then
    BASIC_PACKAGES_TO_INSTALL=(
      epel-release
      perl
      which
      sudo
      wget
      git
      libunwind-devel
      librdkafka-devel
    )
    if [[ "${OS_VERSION}" -eq "8" ]]; then
      ADDITIONAL_PACKAGES=(
        gcc-c++
        python38-devel
        rapidjson-devel
        msgpack-devel
        openssl-devel
        boost-devel
        gflags-devel
        glog-devel
      )
    elif [[ "${OS_VERSION}" -eq "7" ]]; then
      BASIC_PACKAGES_TO_INSTALL+=(centos-release-scl-rh)
      ADDITIONAL_PACKAGES=(
        devtoolset-10-gcc-c++
        rh-python38-python-pip
        rh-python38-python-devel
        rapidjson-devel
        msgpack-devel
      )
    fi
  else # darwin
    BASIC_PACKAGES_TO_INSTALL=(
      boost
      gflags
      glog
      open-mpi
      openssl@1.1
      protobuf
      grpc
      rapidjson
      msgpack-cxx
      librdkafka
    )
  fi
  readonly BASIC_PACKAGES_TO_INSTALL
}

install_grape_vineyard_linux() {
  log "Installing python packages for vineyard codegen."
  pip3 install pip -U --user
  pip3 install libclang wheel --user
  install_grape "${deps_prefix}" "${install_prefix}"
  install_vineyard "${deps_prefix}" "${install_prefix}" "${v6d_version}"
}

install_grape_vineyard_macos() {
  brew install libgrape-lite vineyard
}

install_cppkafka_universal() {
  log "Building and installing cppkafka."

  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    homebrew_prefix=$(brew --prefix)
    export LDFLAGS="-L${homebrew_prefix}/opt/openssl@3/lib"
    export CPPFLAGS="-I${homebrew_prefix}/opt/openssl@3/include"
  fi

  install_cppkafka "${deps_prefix}" "${install_prefix}"
}

install_rust_universal() {
  if ! command -v rustup &>/dev/null; then
    log "Installing rust."
    curl -sf -L https://static.rust-lang.org/rustup.sh | sh -s -- -y --profile minimal
  fi
}

install_java_maven_ubuntu() {
  if ! command -v javac &>/dev/null; then
    # log "Installing openjdk-8-jdk"
    # apt-get install openjdk-8-jdk -y
    log "Installing default-jdk"
    apt-get install default-jdk -y
  fi
  if ! command -v mvn &>/dev/null; then
    log "Installing maven"
    apt-get install maven -y
  fi
}

install_java_maven_centos() {
  if ! command -v javac &>/dev/null; then
    log "Installing java-1.8.0-openjdk-devel"
    yum install java-1.8.0-openjdk-devel -y
  fi
  if ! command -v mvn &>/dev/null; then
    log "Installing maven"
    install_maven  "${deps_prefix}" "${install_prefix}"
  fi
}

install_java_maven_macos() {
  if ! command -v javac &>/dev/null; then
    log "Installing openjdk@11"
    # we need arm64-base jvm, install from brew.
    brew install --ignore-dependencies openjdk@11
  fi
  if ! command -v mvn &>/dev/null; then
    log "Installing maven"
    brew install --ignore-dependencies maven
  fi
}

install_apache_arrow_ubuntu() {
  log "Installing apache-arrow."
  # shellcheck disable=SC2046,SC2019,SC2018
  wget -c https://apache.jfrog.io/artifactory/arrow/"$(lsb_release --id --short | tr 'A-Z' 'a-z')"/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    -P /tmp/
  apt-get install -y -V /tmp/apache-arrow-apt-source-latest-"$(lsb_release --codename --short)".deb
  apt-get update -y && apt-get install -y libarrow-dev
  rm /tmp/apache-arrow-apt-source-latest-*.deb
}

install_deps_ubuntu() {
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  # shellcheck disable=SC2086
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y ${BASIC_PACKAGES_TO_INSTALL[*]}

  install_apache_arrow_ubuntu
  install_java_maven_ubuntu
}

install_deps_centos_pre() {
    log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
    # shellcheck disable=SC2086
    yum install -y ${BASIC_PACKAGES_TO_INSTALL[*]}
    log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
    # shellcheck disable=SC2086
    yum install -y ${ADDITIONAL_PACKAGES[*]}
    install_cmake  "${deps_prefix}" "${install_prefix}"
}

install_deps_centos_after() {
  install_apache_arrow "${deps_prefix}" "${install_prefix}"
  install_open_mpi "${deps_prefix}" "${install_prefix}"
  install_protobuf "${deps_prefix}" "${install_prefix}"
  install_zlib "${deps_prefix}" "${install_prefix}"
  install_grpc "${deps_prefix}" "${install_prefix}"

  install_java_maven_centos
}
install_deps_centos7() {
  install_deps_centos_pre

  source /opt/rh/devtoolset-10/enable
  source /opt/rh/rh-python38/enable
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${install_prefix}/lib:${install_prefix}/lib64

  install_gflags "${deps_prefix}" "${install_prefix}"
  install_glog "${deps_prefix}" "${install_prefix}"
  install_boost "${deps_prefix}" "${install_prefix}"
  install_openssl "${deps_prefix}" "${install_prefix}"

  install_deps_centos_after
}

install_deps_centos8() {
  sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
  sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
  yum install -y 'dnf-command(config-manager)'
  dnf install -y epel-release
  dnf config-manager --set-enabled epel
  dnf config-manager --set-enabled powertools

  install_deps_centos_pre
  install_deps_centos_after
}

install_deps_macos() {
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
  # shellcheck disable=SC2086
  brew install ${BASIC_PACKAGES_TO_INSTALL[*]} || true

  brew install llvm

  install_java_maven_macos

  homebrew_prefix=$(brew --prefix)
  export OPENSSL_ROOT_DIR=${homebrew_prefix}/opt/openssl
  export OPENSSL_LIBRARIES=${homebrew_prefix}/opt/openssl/lib
  export OPENSSL_SSL_LIBRARY=${homebrew_prefix}/opt/openssl/lib/libssl.dylib
  export CC=${homebrew_prefix}/opt/llvm/bin/clang
  export CXX=${homebrew_prefix}/opt/llvm/bin/clang++
  export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=${CC}
  export CPPFLAGS=-I${homebrew_prefix}/opt/llvm/include
}

install_dependencies() {
  # install dependencies for specific platforms.
  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    install_deps_macos
    if [[ -z ${no_grape_v6d} ]]; then
      install_grape_vineyard_macos
    fi
  else
    if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
      install_deps_ubuntu
    elif [[ "${OS_PLATFORM}" == *"CentOS"* ]]; then
      if [[ "${OS_VERSION}" -eq "8" ]]; then
        install_deps_centos8
      elif [[ "${OS_VERSION}" -eq "7" ]]; then
        install_deps_centos7
      fi
    fi
    if [[ -z ${no_grape_v6d} ]]; then
      install_grape_vineyard_linux
    fi
  fi

  install_rust_universal
  install_cppkafka_universal

  log "Output environments config file ${OUTPUT_ENV_FILE}"
  write_env_config
}

write_env_config() {
  if [ -f "${OUTPUT_ENV_FILE}" ]; then
    warning "Found ${OUTPUT_ENV_FILE} exists, remove the environment config file and generate a new one."
    rm -rf "${OUTPUT_ENV_FILE}"
  fi

  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    homebrew_prefix=$(brew --prefix)
    {
      echo "export CC=${homebrew_prefix}/opt/llvm/bin/clang"
      echo "export CXX=${homebrew_prefix}/opt/llvm/bin/clang++"
      echo "export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=${CC}"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=\$(/usr/libexec/java_home -v11)"
      fi
      echo "export PATH=\$HOME/.cargo/bin:\${JAVA_HOME}/bin:/usr/local/go/bin:\$PATH"
      echo "export OPENSSL_ROOT_DIR=${homebrew_prefix}/opt/openssl"
      echo "export OPENSSL_LIBRARIES=${homebrew_prefix}/opt/openssl/lib"
      echo "export OPENSSL_SSL_LIBRARY=${homebrew_prefix}/opt/openssl/lib/libssl.dylib"
    } >>"${OUTPUT_ENV_FILE}"

  elif [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
    {
      echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=/usr/lib/jvm/default-java"
      fi
      echo "export PATH=\${JAVA_HOME}/bin:\$HOME/.cargo/bin:\$PATH"
    } >>"${OUTPUT_ENV_FILE}"
  else
    {
      if [[ "${OS_VERSION}" -eq "7" ]]; then
        echo "source /opt/rh/devtoolset-10/enable"
        echo "source /opt/rh/rh-python38/enable"
      fi
      echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=/usr/lib/jvm/java"
      fi
      echo "export PATH=\${JAVA_HOME}/bin:\$HOME/.cargo/bin:\$PATH"
    } >>"${OUTPUT_ENV_FILE}"
  fi
}

init_workspace_and_env() {
  mkdir -p "${install_prefix}"
  mkdir -p "${deps_prefix}"
  export PATH=${install_prefix}/bin:${PATH}
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${install_prefix}/lib:${install_prefix}/lib64
}

install_deps_for_dev() {
  # install_deps for development on local
  check_os_compatibility

  init_basic_packages

  init_workspace_and_env

  install_dependencies

  succ "The script has installed all dependencies for building GraphScope, use commands:\n
  $ source ${OUTPUT_ENV_FILE}
  $ make install\n
  to build and develop GraphScope."
}

install_deps_for_client() {
  # install python..
  # TODO: refine
  pip3 install -U pip
  pip3 --no-cache-dir install auditwheel==5.0.0 daemons etcd-distro gremlinpython \
          hdfs3 fsspec oss2 s3fs ipython kubernetes libclang networkx==2.4 numpy pandas parsec pycryptodome \
          pyorc pytest scipy scikit_learn wheel
  pip3 --no-cache-dir install Cython --pre -U
}

# run subcommand with the type
install_deps_for_"${type}"
