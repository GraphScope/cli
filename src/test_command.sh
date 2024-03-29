inspect_args

testdata=${args[--testdata]}
on_local=${args[--local]}
storage_type=${args[--storage-type]}
on_k8s=${args[--k8s]}
nx=${args[--nx]}
export GS_TEST_DIR=${testdata}

# analytical, analytical-java, interactive, learning, e2e, groot

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
	info "Testing analytical on local"
	"${GS_SOURCE_DIR}"/analytical_engine/test/app_tests.sh --test_dir "${GS_TEST_DIR}"
}

function test_analytical-java {
	get_test_data
	info "Testing analytical-java on local"

	pushd "${GS_SOURCE_DIR}"/analytical_engine/java || exit
	mvn test -Dmaven.antrun.skip=true
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
		if [[ ${storage_type} = "experimental" ]]; then
			info "Testing interactive on local with experimental storage"
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
		elif [[ ${storage_type} = "vineyard" ]]; then
			info "Testing interactive on local with vineyard storage"
			# start vineyard service
			export VINEYARD_IPC_SOCKET=/tmp/vineyard.sock
			vineyardd --socket=${VINEYARD_IPC_SOCKET} --meta=local &
			# load modern graph
			export STORE_DATA_PATH="${GS_SOURCE_DIR}"/charts/gie-standalone/data
			vineyard-graph-loader --config "${GS_SOURCE_DIR}"/charts/gie-standalone/config/v6d_modern_loader.json
			# start gie executor && frontend
			export GRAPHSCOPE_HOME="${GS_SOURCE_DIR}"/interactive_engine/assembly/target/graphscope
			schema_json=$(ls /tmp/*.json | head -1)
			object_id=${schema_json//[^0-9]/}
			GRAPHSCOPE_HOME=${GRAPHSCOPE_HOME} ${GRAPHSCOPE_HOME}/bin/giectl create_gremlin_instance_on_local /tmp/gs/${object_id} ${object_id} ${schema_json} 1 1235 1234 8182 ${VINEYARD_IPC_SOCKET}
			# IR integration test
			sleep 3s
			cd "${GS_SOURCE_DIR}"/interactive_engine/compiler
			make gremlin_test || true
			# clean
			rm -rf /tmp/*.json
			id=$(pgrep -f 'gaia_executor')
			if [[ -n ${id} ]]; then
				echo ${id} | xargs kill
			fi
			id=$(pgrep -f 'frontend')
			if [[ -n ${id} ]]; then
				echo ${id} | xargs kill
			fi
			id=$(pgrep -f 'vineyardd')
			if [[ -n ${id} ]]; then
				echo ${id} | xargs kill -9
			fi
		else
			info "Testing interactive on local with default storage"
		fi
	fi
	if [[ -n ${on_k8s} ]]; then
		info "Testing interactive on k8s"
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

function test_e2e {
	get_test_data
	cd "${GS_SOURCE_DIR}"/python || exit
	if [[ -n ${on_local} ]]; then
		# unittest
		python3 -m pytest -s -vvv --exitfirst graphscope/tests/minitest/test_min.py
	fi
	if [[ -n ${on_k8s} ]]; then
		python3 -m pytest -s -vvv --exitfirst ./graphscope/tests/kubernetes/test_demo_script.py
	fi
}

function test_groot {
	get_test_data
	if [[ -n ${on_local} ]]; then
		info "Testing groot on local"
		cd "${GS_SOURCE_DIR}"/interactive_engine/groot-server
		mvn test -Pgremlin-test
	fi
	if [[ -n ${on_k8s} ]]; then
		info "Testing groot on k8s, note you must already setup a groot cluster and necessary environment variables"
		cd "${GS_SOURCE_DIR}"/python || exit
		python3 -m pytest --exitfirst -s -vvv ./graphscope/tests/kubernetes/test_store_service.py
	fi
}

test_"${type}"
