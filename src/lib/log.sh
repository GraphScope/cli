err() {
  echo -e "$(yellow_bold "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [ERROR] $*${NC}")" >&2
}

warning() {
  echo -e "$(yellow_bold "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: [WARNING] $*${NC}")" >&1
}

log() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&1
}

succ() {
  echo -e "$(green_bold "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}")" >&1
}
