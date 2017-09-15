#!/usr/bin/env bash

[[ -z  $appdir  ]] && echo "请先设置环境变量appdir ,指向etcd目录" && exit

host=$1
[[ -z  $host  ]] && echo "missing parameter: host" && exit

nodename="node$RANDOM"

container=`docker run --rm -dt -P  -p ${host}:2379:2379 -p ${host}:2380:2380 -v `pwd`/docker/:/app --name etcd_${nodename} busybox`
[[ -z  $container  ]] && echo "can't start container" && exit

portpeer=`docker port $container 2380 | cut -d':' -f2`
[[ -z  $portpeer  ]] && echo "can't get peer port on host" && exit

portclient=`docker port $container 2379 | cut -d':' -f2`
[[ -z  $portclient  ]] && echo "can't get client port on host" && exit

containerip=`docker exec $container /bin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
[[ -z  $containerip  ]] && echo "can't get container ip" && exit

docker exec -d $container /etcd --listen-peer-urls "http://$containerip:4000" --listen-client-urls "http://$containerip:4001" --initial-advertise-peer-urls "http://$host:$portpeer" --initial-cluster "$nodename=http://$host:$portpeer" --advertise-client-urls "http://$host:$portclient" --initial-cluster-state=new  --name=$nodename

echo "Your etcd cluster's endpoint is"
echo "$host:$portclient"