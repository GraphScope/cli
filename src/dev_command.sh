inspect_args

local=${args[--local]}
if [[ -n $local ]]; then
    echo "local=" $local
else
    echo "No local assigned, use default `pwd` to mount as working directory."
    local=`pwd`
fi

docker pull registry.cn-hongkong.aliyuncs.com/graphscope/graphscope-dev
docker run \
    -v $local:/home/graphscope \
    --net=host \
    -it registry.cn-hongkong.aliyuncs.com/graphscope/graphscope-dev \
    /bin/bash
