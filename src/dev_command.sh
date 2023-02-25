inspect_args

local=${args[--local]}
if [[ -n $local ]]; then
    echo "local=" $local
else
    echo "No local assigned, use default `pwd` to mount as working directory."
    local=`pwd`
fi

#docker pull graphscope/graphscope-dev
docker run \
    -it graphscope/graphscope-dev \
    /bin/bash


    # -v $local:/home/graphscope/workspace 