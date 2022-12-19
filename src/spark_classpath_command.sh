#!/bin/bash
echo "# this file is located in 'src/spark_classpath_command.sh'"
echo "# code for 'gs spark-classpath' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"

set -e

err() {
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [ERROR] $*${NC}" >&2
}

warning() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [WARNING] $*${NC}" >&1
}

log() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&1
}

succ() {
  echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}" >&1
}

# check if the file exists
# if yes, raise a warning
# otherwise, generate a new
target_file_name="${HOME}/.graphscope_4spark.env"
if [[ -f "${target_file_name}" ]];then
    warning "Exiting .graphscope_4spark.env found, still proceed..."
    rm -fr ${target_file_name}
fi

if [[ "$GRAPHSCOPE_HOME"x == x ]];
then
    log "No GRAPHSCOPE_HOME found, infer from python package"
    site_path=`python3 -c "import graphscope;import os; p = os.path.dirname(os.path.dirname(graphscope.__file__)); print(p)"`
    gs_runtime_dir=${site_path}/graphscope.runtime/
    if [[ -d ${gs_runtime_dir}  ]];then
        export GRAPHSCOPE_HOME=${gs_runtime_dir}
        log "Infered GRAPHSCOPE_HOME "${gs_runtime}
    else
        err "Failed to infer GRAPHSCOPE_HOME from current environment, try pip3 install graphscope."
        exit 1;
    fi
else
    log "using existing GRAPHSCOPE_HOME ${GRAPHSCOPE_HOME}"
fi

{
  export GRAPHX_GRAPE_SDK=`ls ${GRAPHSCOPE_HOME}/lib/grape-graphx-*.jar`
  export GRAPE_RUNTIME_JAR=`ls ${GRAPHSCOPE_HOME}/lib/grape-runtime-*.jar`
  echo "export GS_JARS=${GRAPHX_GRAPE_SDK}:${GRAPE_RUNTIME_JAR}"
} >> ${target_file_name}

succ "Generated environment variables for spark jobs in ~/.graphscope_4spark.env"
succ "export the env to your bash terminal by running: source ~/.graphscope_4spark.env"