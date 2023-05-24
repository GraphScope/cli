echo "# this file is located in 'src/test_command.sh'"
echo "# code for 'gs test' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

testdata=${args[--testdata]}
on_local=${args[--local]}
on_k8s=${args[--k8s]}
nx=${args[--nx]}
export GS_TEST_DIR=${testdata}

# analytical, analytical-java, interactive, learning, local-e2e, k8s-e2e, groot

type=${args[type]}

GS_SOURCE_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"


function get_test_data {
  if [[ ! -d ${GS_TEST_DIR} ]]; then
    log "Downloading test data to ${testdata}"
    git clone -b master --single-branch --depth=1 https://github.com/graphscope/gstest.git "${GS_TEST_DIR}"
  fi
}

function test_analytical {
  get_test_data
  "${GS_SOURCE_DIR}"/analytical_engine/test/app_tests.sh --test_dir "${GS_TEST_DIR}"
}

function test_analytical-java {
  get_test_data

  pushd "${GS_SOURCE_DIR}"/analytical_engine/java || exit
  mvn test -Dmaven.antrun.skip=true --quiet
  popd || exit

  version=$(cat "${GS_SOURCE_DIR}"/VERSION)
  export RUN_JAVA_TESTS=ON
  export USER_JAR_PATH="${GS_SOURCE_DIR}"/analytical_engine/java/grape-demo/target/grape-demo-${version}-shaded.jar
  # for giraph test
  export GIRAPH_JAR_PATH="${GS_SOURCE_DIR}"/analytical_engine/java/grape-giraph/target/grape-giraph-${version}-shaded.jar

  "${GS_SOURCE_DIR}"/analytical_engine/test/app_tests.sh --test_dir "${GS_TEST_DIR}"
}

function test_interactive {
  get_test_data
  if [[ -n ${on_local} ]]; then
    # IR unit test
    cd "${GS_SOURCE_DIR}"/interactive_engine/compiler && make test
    # CommonType Unit Test
    cd "${GS_SOURCE_DIR}"/interactive_engine/executor/common/dyn_type && cargo test
    # Store Unit test
    cd "${GS_SOURCE_DIR}"/interactive_engine/executor/store/exp_store && cargo test

    # IR integration test
    cd "${GS_SOURCE_DIR}"/interactive_engine/compiler && ./ir_exprimental_ci.sh
    # IR integration pattern test
    cd "${GS_SOURCE_DIR}"/interactive_engine/compiler && ./ir_exprimental_pattern_ci.sh
  else
    export PYTHONPATH="${GS_SOURCE_DIR}"/python:${PYTHONPATH}
    cd "${GS_SOURCE_DIR}"/interactive_engine && mvn clean install --quiet -DskipTests -Drust.compile.skip=true -P graphscope,graphscope-assembly
    cd "${GS_SOURCE_DIR}"/interactive_engine/tests || exit
    ./function_test.sh 8112 2
  fi
}
function test_learning {
  get_test_data
  err "Not implemented"
  exit 1
}

function test_local-e2e {
  get_test_data
  cd "${GS_SOURCE_DIR}"/python || exit

  # unittest
  python3 -m pytest -s -vvv --exitfirst graphscope/tests/minitest/test_min.py
}

function test_k8s-e2e {
  get_test_data
  cd "${GS_SOURCE_DIR}"/python || exit
  python3 -m pytest -s -vvv --exitfirst ./graphscope/tests/kubernetes/test_demo_script.py
}

function test_for_groot {
  get_test_data
  cd "${GS_SOURCE_DIR}"/python || exit
  python3 -m pytest --exitfirst -s -vvv ./graphscope/tests/kubernetes/test_store_service.py
}

test_"${type}"
