#!/usr/bin/env bash

[[ -z  $appdir  ]] && echo "请先设置环境变量appdir ,指向etcd目录" && exit

clients=$1
[[ -z  $clients  ]] && echo "missing first parameter: first node's client ip:port" && exit

host=$2
[[ -z  $host  ]] && echo "missing second parameter: host" && exit

nodename="node$RANDOM"

container=`docker run --rm -dt -P -p ${host}:2379:2379 -p ${host}:2380:2380 -v ${appdir}:/app --name etcd_${nodename} busybox`
[[ -z  $container  ]] && echo "can't run container" && exit

portpeer=`docker port $container 2380 | cut -d':' -f2`
[[ -z  $portpeer  ]] && echo "can't get peer 2380 port" && exit

portclient=`docker port $container 2379 | cut -d':' -f2`
[[ -z  $portclient  ]] && echo "can't get 2379 port" && exit

containerip=`docker exec $container /bin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
[[ -z  $containerip  ]] && echo "can't get container ip" && exit

cluster=`docker exec $container /app/etcdctl --endpoint=$clients member add $nodename "http://$host:$portpeer" | grep ETCD_INITIAL_CLUSTER= | cut -d'"' -f2`
[[ -z  $cluster  ]] && echo "can't add to cluster" && exit

docker exec -d $container /app/etcd --listen-peer-urls "http://$containerip:2380" --listen-client-urls "http://$containerip:2379" --initial-advertise-peer-urls "http://$host:$portpeer" --initial-cluster $cluster --advertise-client-urls "http://$host:$portclient" --initial-cluster-state=existing  --name=$nodename

echo "deployment is successful. your client endpoint is "
echo "$host:$portclient"