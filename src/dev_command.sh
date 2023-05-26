inspect_args

local=${args[--local]}

mount_option=""

if [[ -n $local ]]; then
	echo "Opened a new container with $local mounted to /home/graphscope/graphscope."
	mount_option="--mount type=bind,source=${local},target=/home/graphscope/graphscope"
else
	echo "No local directory assigned, open a new container without mounting local directory."
fi

# docker pull graphscope/graphscope-dev
REGISTRY="registry.cn-hongkong.aliyuncs.com"
docker run \
	-it \
	${mount_option} \
	${REGISTRY}/graphscope/graphscope-dev:latest
