inspect_args
type=${args[type]}
# from-local=${args[--from-local]}
cn=${args[--cn]}
only_grape_v6d=${args[--only-grape-v6d]}
# no-grape-v6d=${args[--no-grape-v6d]}

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    error "Not running as root."
    exit 2
else
    warning "Please note that I am running as root."
fi

readonly OS=$(get_os_version)
readonly OS_PLATFORM=${OS%-*}
readonly OS_VERSION=${OS#*-}

readonly OUTPUT_ENV_FILE="${HOME}/.graphscope_env"
DEPS_PREFIX="/usr/local"
BASIC_PACKGES_TO_INSTALL=

# TODO: remove these 3 lines, seperate install grape/vineyard script to lib, 
# always intall the latest, in order to support graphscope-dev-base and graphscope-dev
readonly GRAPE_BRANCH="master" # libgrape-lite branch
readonly V6D_VERSION="0.11.1"  # vineyard version
readonly V6D_BRANCH="v0.11.1" # vineyard branch

packages_to_install=()

echo "$(green_bold "Installing ${type} dependencies for GraphScope on ${OS}...")"

if [[ -n $cn ]]; then
    echo "$(green "Set to speed up downloading for CN locations.")"
    # export some mirror locations for CN, e.g., brew/docker...
    export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
fi


if [[ -n $only_grape_v6d ]]; then
  echo "$(yellow "Only install libgrape and vineyard.")"
  install_grape
  install_vineyard
  exit 0
fi

check_os_compatibility() {
  if [[ "${OS_PLATFORM}" != *"Ubuntu"* && "${OS_PLATFORM}" != *"CentOS"* && "${OS_PLATFORM}" != *"Darwin"* ]]; then
    err "The script is only support platforms of Ubuntu/CentOS/macOS"
    exit 1
  fi

  if [[ "${OS_PLATFORM}" == *"Ubuntu"* && "$(echo ${OS_VERSION} | sed 's/\([0-9]\)\([0-9]\).*/\1\2/')" -lt "20" ]]; then
    err "The version of Ubuntu is ${OS_VERSION}. This script requires Ubuntu 20 or greater."
    exit 1
  fi

  if [[ "${OS_PLATFORM}" == *"CentOS"* && "${OS_VERSION}" -lt "8" ]]; then
    err "The version of CentOS is ${OS_VERSION}. This script requires CentOS 8 or greater."
    exit 1
  fi

  log "Runing on ${OS_PLATFORM} ${OS_VERSION}"
}

init_basic_packages() {
  if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
    BASIC_PACKGES_TO_INSTALL=(
      build-essential
      wget
      curl
      lsb-release
      libbrotli-dev
      libbz2-dev
      libclang-dev
      libcurl4-openssl-dev
      protobuf-compiler-grpc
      libevent-dev
      libgflags-dev
      libgoogle-glog-dev
      libgrpc-dev
      libgrpc++-dev
      libgtest-dev
      libgsasl7-dev
      libtinfo5
      libkrb5-dev
      liblz4-dev
      libprotobuf-dev
      librdkafka-dev
      libre2-dev
      libc-ares-dev
      libsnappy-dev
      libssl-dev
      libunwind-dev
      libutf8proc-dev
      libxml2-dev
      libz-dev
      libzstd-dev
      lsb-release
      zlib1g-dev
      uuid-dev
      zip
      perl
      python3-pip
      git
      rapidjson-dev
      libmsgpack-dev
    )
  elif [[ "${OS_PLATFORM}" == *"CentOS"* ]]; then
    BASIC_PACKGES_TO_INSTALL=(
      autoconf
      automake
      clang-devel
      git
      zlib-devel
      libcurl-devel
      libevent-devel
      libgsasl-devel
      librdkafka-devel
      libunwind-devel
      libuuid-devel
      libxml2-devel
      libzip
      libzip-devel
      m4
      minizip
      minizip-devel
      net-tools
      openssl-devel
      unzip
      which
      zip
      bind-utils
      perl
      libarchive
      gflags-devel
      glog-devel
      gtest-devel
      gcc
      gcc-c++
      make
      wget
      curl
      rapidjson-devel
      msgpack-devel
    )
  else
    BASIC_PACKGES_TO_INSTALL=(
      coreutils
      protobuf
      glog
      gflags
      grpc
      python3
      zstd
      snappy
      lz4
      openssl
      libevent
      librdkafka
      autoconf
      wget
      libomp
      rapidjson
      msgpack-cxx
    )
  fi
  readonly BASIC_PACKGES_TO_INSTALL
}

check_dependencies() {
  log "Checking dependencies for building GraphScope."

  # check python3 >= 3.7
  if ! command -v python3 &> /dev/null ||
     [[ "$(python3 -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')" -lt "37" ]]; then
    if [[ "${OS_PLATFORM}" == *"CentOS"* ]]; then
      packages_to_install+=(python3-devel)
    else
      packages_to_install+=(python3)
    fi
  fi

  # check cmake >= 3.1
  if $(! command -v cmake &> /dev/null) || \
     [[ "$(cmake --version 2>&1 | awk -F ' ' '/version/ {print $3}')" < "3.1" ]]; then
    packages_to_install+=(cmake)
  fi

  # check java
  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    if [[ ! -z "${JAVA_HOME}" ]]; then
      declare -r java_version=$(${JAVA_HOME}/bin/javac -version 2>&1 | awk -F ' ' '{print $2}' | awk -F '.' '{print $1}')
      if [[ "${java_version}" -lt "8" ]] || [[ "${java_version}" -gt "15" ]]; then
        warning "Found the java version is ${java_version}, do not meet the requirement of GraphScope."
        warning "Would install jdk 11 instead and reset the JAVA_HOME"
        JAVA_HOME=""  # reset JAVA_HOME to jdk11
        packages_to_install+=(openjdk@11)
      fi
    else
      if [[ ! -f "/usr/libexec/java_home" ]] || \
         ! /usr/libexec/java_home -v11 &> /dev/null; then
        packages_to_install+=(openjdk@11)
      fi
    fi
  else
    if $(! command -v javac &> /dev/null) || \
       [[ "$(javac -version 2>&1 | awk -F ' ' '{print $2}' | awk -F '.' '{print $1}')" -lt "7" ]]; then
      if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
        packages_to_install+=(default-jdk)
      else
        packages_to_install+=(java-11-openjdk-devel)  # CentOS
      fi
    fi
  fi

  # check boost >= 1.66
  if [[ ( ! -f "/usr/include/boost/version.hpp" || \
        "$(grep "#define BOOST_VERSION" /usr/include/boost/version.hpp | cut -d' ' -f3)" -lt "106600" ) && \
     ( ! -f "/usr/local/include/boost/version.hpp" || \
       "$(grep "#define BOOST_VERSION" /usr/local/include/boost/version.hpp | cut -d' ' -f3)" -lt "106600" ) && \
     ( ! -f "/opt/homebrew/include/boost/version.hpp" || \
       "$(grep "#define BOOST_VERSION" /opt/homebrew/include/boost/version.hpp | cut -d' ' -f3)" -lt "106600" ) ]]; then
    case "${OS_PLATFORM}" in
      *"Ubuntu"*)
        packages_to_install+=(libboost-all-dev)
        ;;
      *"CentOS"*)
        packages_to_install+=(boost-devel)
        ;;
      *)
        packages_to_install+=(boost)
        ;;
    esac
  fi

  # check apache-arrow
  if [[ ! -f "/usr/local/include/arrow/api.h" && ! -f "/usr/include/arrow/api.h" &&
        ! -f "/opt/homebrew/include/arrow/api.h" ]]; then
    packages_to_install+=(apache-arrow)
  fi

  # check maven
  if ! command -v mvn &> /dev/null; then
    packages_to_install+=(maven)
  fi

  # check rust > 1.52.0
  if ( ! command -v rustup &> /dev/null || \
    [[ "$(rustc --V | awk -F ' ' '{print $2}')" < "1.52.0" ]] ) && \
     ( ! command -v ${HOME}/.cargo/bin/rustup &> /dev/null || \
    [[ "$(${HOME}/.cargo/bin/rustc --V | awk -F ' ' '{print $2}')" < "1.52.0" ]] ); then
    packages_to_install+=(rust)
  fi

  # check etcd
  if ! command -v etcd &> /dev/null; then
    packages_to_install+=(etcd)
  fi

  # check mpi
  if ! command -v mpiexec &> /dev/null; then
    if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
      packages_to_install+=(libopenmpi-dev)
    else
      packages_to_install+=(openmpi)
    fi
  fi

  # check c++ compiler
  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    if [ ! -d $(brew --prefix llvm) ]; then
        packages_to_install+=("llvm")
    fi
  else
    if ! command -v g++ &> /dev/null; then
      if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
        packages_to_install+=(build-essential)
      else
        packages_to_install+=(gcc gcc-c++)
      fi
    fi
  fi
}


check_and_remove_dir() {
  if [[ -d $1 ]]; then
    log "Found $1 exists, remove it."
    rm -fr $1
  fi
}

install_cppkafka() {
  log "Building and installing cppkafka."

  if [[ -f "/usr/local/include/cppkafka/cppkafka.h" ]]; then
    log "cppkafka already installed, skip."
    return 0
  fi

  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    declare -r homebrew_prefix=$(brew --prefix)
    export LDFLAGS="-L${homebrew_prefix}/opt/openssl@3/lib"
    export CPPFLAGS="-I${homebrew_prefix}/opt/openssl@3/include"
  fi

  check_and_remove_dir "/tmp/cppkafka"
  git clone -b 0.4.0 --single-branch --depth=1 \
      https://github.com/mfontanini/cppkafka.git /tmp/cppkafka
  pushd /tmp/cppkafka
  git submodule update --init
  mkdir -p build && pushd build
  cmake -DCPPKAFKA_DISABLE_TESTS=ON  -DCPPKAFKA_DISABLE_EXAMPLES=ON .. && make -j$(nproc)
  make install && popd
  popd

  rm -fr /tmp/cppkafka
}

install_dependencies() {
  # install dependencies for specific platforms.
  if [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
    apt-get update -y

    log "Installing packages ${BASIC_PACKGES_TO_INSTALL[*]}"
    apt-get install -y ${BASIC_PACKGES_TO_INSTALL[*]}

    if [[ "${packages_to_install[*]}" =~ "rust" ]]; then
      # packages_to_install contains rust
      log "Installing rust."
      curl -sf -L https://static.rust-lang.org/rustup.sh | sh -s -- -y --profile minimal --default-toolchain 1.60.0
      # remove rust from packages_to_install
      packages_to_install=("${packages_to_install[@]/rust}")
    fi

    if [[ "${packages_to_install[*]}" =~ "apache-arrow" ]]; then
      log "Installing apache-arrow."
      wget -c https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
        -P /tmp/
      apt install -y -V /tmp/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
      apt update -y
      apt install -y libarrow-dev
      # remove apache-arrow from packages_to_install
      packages_to_install=("${packages_to_install[@]/apache-arrow}")
    fi

    if [[ ! -z "${packages_to_install}" ]]; then
      log "Installing packages ${packages_to_install[*]}"
      apt install -y ${packages_to_install[*]}
    fi

  elif [[ "${OS_PLATFORM}" == *"CentOS"* ]]; then
    dnf install -y dnf-plugins-core \
        https://download-ib01.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

    dnf config-manager --set-enabled epel
    dnf config-manager --set-enabled powertools

    log "Instralling packages ${BASIC_PACKGES_TO_INSTALL[*]}"
    dnf install -y ${BASIC_PACKGES_TO_INSTALL[*]}

    if [[ "${packages_to_install[*]}" =~ "apache-arrow" ]]; then
      log "Installing apache-arrow."
      dnf install -y libarrow-devel
      # remove apache-arrow from packages_to_install
      packages_to_install=("${packages_to_install[@]/apache-arrow}")
    fi

    if [[ "${packages_to_install[*]}" =~ "openmpi" ]]; then
      log "Installing openmpi v4.0.5"
      wget -c https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz -P /tmp
      check_and_remove_dir "/tmp/openmpi-4.0.5"
      tar zxvf /tmp/openmpi-4.0.5.tar.gz -C /tmp
      pushd /tmp/openmpi-4.0.5 && ./configure --enable-mpi-cxx
      make -j$(nproc)
      make install
      popd
      rm -fr /tmp/openmpi-4.0.5 /tmp/openmpi-4.0.5.tar.gz
      packages_to_install=("${packages_to_install[@]/openmpi}")
    fi

    if [[ "${packages_to_install[*]}" =~ "etcd" ]]; then
      log "Installing etcd v3.4.13"
      check_and_remove_dir "/tmp/etcd-download-test"
      mkdir -p /tmp/etcd-download-test
      export ETCD_VER=v3.4.13 && \
      export DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download && \
      curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz \
        -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
      tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz \
        -C /tmp/etcd-download-test --strip-components=1
      mv /tmp/etcd-download-test/etcd /usr/local/bin/
      mv /tmp/etcd-download-test/etcdctl /usr/local/bin/
      rm -fr /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz /tmp/etcd-download-test
      packages_to_install=("${packages_to_install[@]/etcd}")
    fi

    if [[ "${packages_to_install[*]}" =~ "rust" ]]; then
      # packages_to_install contains rust
      log "Installing rust."
      curl -sf -L https://static.rust-lang.org/rustup.sh | sh -s -- -y --profile minimal --default-toolchain 1.60.0
      # remove rust from packages_to_install
      packages_to_install=("${packages_to_install[@]/rust}")
    fi

    if [[ ! -z "${packages_to_install}" ]]; then
      log "Installing packages ${packages_to_install[*]}"
      dnf -y install  ${packages_to_install[*]}
    fi

    log "Installing protobuf v.3.13.0"
    wget -c https://github.com/protocolbuffers/protobuf/releases/download/v3.13.0/protobuf-all-3.13.0.tar.gz -P /tmp
    check_and_remove_dir "/tmp/protobuf-3.13.0"
    tar zxvf /tmp/protobuf-all-3.13.0.tar.gz -C /tmp/
    pushd /tmp/protobuf-3.13.0
    ./configure --enable-shared --disable-static
    make -j$(nproc)
    make install && ldconfig
    popd
    rm -fr /tmp/protobuf-all-3.13.0.tar.gz /tmp/protobuf-3.13.0

    log "Installing grpc v1.33.1"
    if [[ -d "/tmp/grpc" ]]; then
      rm -fr /tmp/grpc
    fi
    git clone --depth 1 --branch v1.33.1 https://github.com/grpc/grpc.git /tmp/grpc
    pushd /tmp/grpc
    git submodule update --init
    mkdir -p build && cd build
    cmake .. -DBUILD_SHARED_LIBS=ON \
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
        -DgRPC_SSL_PROVIDER=package
    make -j$(nproc)
    make install
    popd
    rm -fr /tmp/grpc

    export LD_LIBRARY_PATH=/usr/local/lib

  elif [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    log "Installing packages ${BASIC_PACKGES_TO_INSTALL[*]}"
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
    brew install ${BASIC_PACKGES_TO_INSTALL[*]} || true

    if [[ -n $cn && "${packages_to_install[*]}" =~ "openjdk@11" ]]; then
      # packages_to_install contains jdk
      log "Installing openjdk11."
      # we need arm64-base jvm, install from brew.
      brew install --ignore-dependencies openjdk@11
      # remove jdk from packages_to_install
      packages_to_install=("${packages_to_install[@]/openjdk@11}")
    fi

    if [[ "${packages_to_install[*]}" =~ "rust" ]]; then
      # packages_to_install contains rust
      log "Installing rust."
      curl -sf -L https://static.rust-lang.org/rustup.sh | sh -s -- -y --profile minimal --default-toolchain 1.60.0
      # remove rust from packages_to_install
      packages_to_install=("${packages_to_install[@]/rust}")
    fi

    if [[ "${packages_to_install[*]}" =~ "maven" ]]; then
      # install maven ignore openjdk dependencies
      brew install --ignore-dependencies maven
      packages_to_install=("${packages_to_install[@]/maven}")
    fi

    if [[ ! -z "${packages_to_install}" ]]; then
      log "Installing packages ${packages_to_install[*]}"
      brew install ${packages_to_install[*]} || true
    fi

    declare -r homebrew_prefix=$(brew --prefix)
    export OPENSSL_ROOT_DIR=${homebrew_prefix}/opt/openssl
    export OPENSSL_LIBRARIES=${homebrew_prefix}/opt/openssl/lib
    export OPENSSL_SSL_LIBRARY=${homebrew_prefix}/opt/openssl/lib/libssl.dylib
    export CC=${homebrew_prefix}/opt/llvm/bin/clang
    export CXX=${homebrew_prefix}/opt/llvm/bin/clang++
    export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=${CC}
    export CPPFLAGS=-I${homebrew_prefix}/opt/llvm/include
  fi

  log "Installing python packages for vineyard codegen."
  pip3 install -U pip --user
  pip3 install grpcio-tools libclang parsec setuptools wheel twine --user

  install_libgrape-lite

  install_vineyard

  install_cppkafka

  log "Output environments config file ${OUTPUT_ENV_FILE}"
  write_envs_config
}

write_envs_config() {
  if [ -f "${OUTPUT_ENV_FILE}" ]; then
    warning "Found ${OUTPUT_ENV_FILE} exists, remove the environmen config file and generate a new one."
    rm -fr ${OUTPUT_ENV_FILE}
  fi

  if [[ "${OS_PLATFORM}" == *"Darwin"* ]]; then
    declare -r homebrew_prefix=$(brew --prefix)
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
    } >> ${OUTPUT_ENV_FILE}

  elif [[ "${OS_PLATFORM}" == *"Ubuntu"* ]]; then
    {
      echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib:/usr/local/lib64"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=/usr/lib/jvm/default-java"
      fi
      echo "export PATH=\${JAVA_HOME}/bin:\$HOME/.cargo/bin:\$PATH"
    } >> ${OUTPUT_ENV_FILE}
  else
    {
      echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib:/usr/local/lib64"
      if [ -z "${JAVA_HOME}" ]; then
        echo "export JAVA_HOME=/usr/lib/jvm/java"
      fi
      echo "export PATH=\${JAVA_HOME}/bin:\$HOME/.cargo/bin:\$PATH"
    } >> ${OUTPUT_ENV_FILE}
  fi
}

install_deps_for_dev(){
  echo "TODO"
  # install_deps for development on local
  check_os_compatibility

  init_basic_packages

  check_dependencies

  install_dependencies

  succ_msg="The script has installed all dependencies for builing GraphScope, use commands:\n
  $ source ${OUTPUT_ENV_FILE}
  $ make install\n
  to build and develop GraphScope."
}

install_deps_for_client(){
    echo "TODO"
    # install python..
}

# run subcommand with the type
install_deps_for_${type}
