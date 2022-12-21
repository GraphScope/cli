inspect_args

type=${args[type]}
# from-local=${args[--from-local]}
cn=${args[--cn]}
only_grape_v6d=${args[--only - grape - v6d]}
# no-grape-v6d=${args[--no-grape-v6d]}

if [[ $(id -u) -ne 0 ]]; then
  error "Not running as root."
  exit 2
else
  warning "Please note that I am running as root."
fi

readonly OS=$(get_os_version)
readonly OS_PLATFORM=${OS%-*}
readonly OS_VERSION=${OS#*-}

readonly OUTPUT_ENV_FILE="${HOME}/.graphscope_env"
export DEPS_PREFIX="/usr/local"
export WORKDIR="/tmp"
export MPI_PREFIX="/opt/openmpi"

BASIC_PACKAGES_TO_INSTALL=

# TODO: remove these 3 lines, separate install grape/vineyard script to lib,
# always install the latest, in order to support graphscope-dev-base and graphscope-dev
export GRAPE_BRANCH="master"        # libgrape-lite branch
export V6D_VERSION="0.11.2"         # vineyard version

log "Installing ${type} dependencies for GraphScope on ${OS}..."

if [[ -n $cn ]]; then
  log "Set to speed up downloading for CN locations."
  # export some mirror locations for CN, e.g., brew/docker...
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
fi

if [[ -n $only_grape_v6d ]]; then
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

  if [[ "${OS_PLATFORM}" == *"Ubuntu"* && "$(echo "${OS_VERSION}" | sed 's/\([0-9]\)\([0-9]\).*/\1\2/')" -lt "20" ]]; then
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
      libopenmpi-dev
      libgflags-dev
      libgoogle-glog-dev
      libboost-all-dev
      libprotobuf-dev
      libgrpc++-dev
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
  pip3 install libclang --user
  install_grape
  install_vineyard
}

install_grape_vineyard_macos() {
  brew install libgrape-lite vineyard
}

install_cppkafka_universal() {
  log "Building and installing cppkafka."

  if [[ -f "/usr/local/include/cppkafka/cppkafka.h" ]]; then
    log "cppkafka already installed, skip."
    return 0
  fi

  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    homebrew_prefix=$(brew --prefix)
    export LDFLAGS="-L${homebrew_prefix}/opt/openssl@3/lib"
    export CPPFLAGS="-I${homebrew_prefix}/opt/openssl@3/include"
  fi

  log "install cpp kafka"
  install_cppkafka
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
    # apt install openjdk-8-jdk -y
    log "Installing default-jdk"
    apt install default-jdk -y
  fi
  if ! command -v mvn &>/dev/null; then
    log "Installing maven"
    apt install maven -y
  fi
}

install_java_maven_centos() {
  if ! command -v javac &>/dev/null; then
    log "Installing java-1.8.0-openjdk-devel"
    apt install java-1.8.0-openjdk-devel -y
  fi
  if ! command -v mvn &>/dev/null; then
    log "Installing maven"
    install_maven
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
  wget -c https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    -P /tmp/
  apt install -y -V /tmp/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
  apt update -y && apt install -y libarrow-dev
  rm /tmp/apache-arrow-apt-source-latest-*.deb
}

install_deps_ubuntu() {
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  apt update -y && apt install -y "${BASIC_PACKAGES_TO_INSTALL[*]}"

  install_apache_arrow_ubuntu
  install_java_maven_ubuntu
}

install_deps_centos_common() {
  install_cmake
  install_apache_arrow
  install_open_mpi
  install_protobuf
  install_grpc

  install_java_maven_centos
}
install_deps_centos7() {
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  yum install -y "${BASIC_PACKAGES_TO_INSTALL[*]}"
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  yum install -y "${ADDITIONAL_PACKAGES[*]}"

  install_gflags
  install_glog
  install_boost
  install_openssl
  install_deps_centos_common
}

install_deps_centos8() {
  sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
  sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
  yum install 'dnf-command(config-manager)'
  dnf install epel-release -y
  dnf config-manager --set-enabled epel
  dnf config-manager --set-enabled powertools

  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  dnf install -y "${BASIC_PACKAGES_TO_INSTALL[*]}"
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  dnf install -y "${ADDITIONAL_PACKAGES[*]}"

  install_deps_centos_common
}

install_deps_macos() {
  log "Installing packages ${BASIC_PACKAGES_TO_INSTALL[*]}"
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
  brew install "${BASIC_PACKAGES_TO_INSTALL[*]}" || true

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
    install_grape_vineyard_macos
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
    install_grape_vineyard_linux
  fi

  install_rust_universal
  install_cppkafka_universal

  log "Output environments config file ${OUTPUT_ENV_FILE}"
  write_envs_config
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
      echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${DEPS_PREFIX}/lib:${DEPS_PREFIX}/lib64"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=/usr/lib/jvm/default-java"
      fi
      echo "export PATH=\${JAVA_HOME}/bin:\$HOME/.cargo/bin:\$PATH"
    } >>"${OUTPUT_ENV_FILE}"
  else
    {
      echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${DEPS_PREFIX}/lib:${DEPS_PREFIX}/lib64"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=/usr/lib/jvm/java"
      fi
      echo "export PATH=\${JAVA_HOME}/bin:\$HOME/.cargo/bin:\$PATH"
    } >>"${OUTPUT_ENV_FILE}"
  fi
}

install_deps_for_dev() {
  echo "TODO"
  # install_deps for development on local
  check_os_compatibility

  init_basic_packages

  install_dependencies

  succ "The script has installed all dependencies for building GraphScope, use commands:\n
  $ source ${OUTPUT_ENV_FILE}
  $ make install\n
  to build and develop GraphScope."
}

install_deps_for_client() {
  echo "TODO"
  # install python..
}

# run subcommand with the type
install_deps_for_"${type}"
