#!/usr/bin/env bash
#https://coreos.com/etcd/docs/latest/demo.html
#On each etcd node, specify the cluster members:
#cat /opt/tools/g.sh
TOKEN=token-01
CLUSTER_STATE=new
NAME_1=machine-1
NAME_2=machine-2
NAME_3=machine-3
NAME_4=machine-4
HOST_1=172.17.165.224
HOST_2=172.17.165.225
HOST_3=172.17.165.227
HOST_4=172.17.165.228
NAME_5=machine-5
HOST_5=172.17.165.231
CLUSTER=${NAME_1}=http://${HOST_1}:2380,${NAME_2}=http://${HOST_2}:2380,${NAME_3}=http://${HOST_3}:2380,${NAME_4}=http://${HOST_4}:2380
Endpoints=http://${HOST_1}:2379,http://${HOST_2}:2379,http://${HOST_3}:2379,http://${HOST_4}:2379
echo $CLUSTER
#Run this on each machine:

# For machine 1
#. /opt/tools/g.sh
THIS_NAME=${NAME_1}
THIS_IP=${HOST_1}
nohup /opt/tools/etcd/etcd --data-dir=/data/etcd --name ${THIS_NAME} \
	--initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
	--advertise-client-urls http://0.0.0.0:2379 --listen-client-urls http://0.0.0.0:2379 \
	--initial-cluster ${CLUSTER} \
	--initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} \
	>> /data/etcd/log.log 2>&1 &

# For machine 2
#. /opt/tools/g.sh
THIS_NAME=${NAME_2}
THIS_IP=${HOST_2}
nohup /opt/tools/etcd/etcd --data-dir=/data/etcd --name ${THIS_NAME} \
	--initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
	--advertise-client-urls http://0.0.0.0:2379 --listen-client-urls http://0.0.0.0:2379 \
	--initial-cluster ${CLUSTER} \
	--initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} \
	>> /data/etcd/log.log 2>&1 &

# For machine 3
#. /opt/tools/g.sh
THIS_NAME=${NAME_3}
THIS_IP=${HOST_3}
nohup /opt/tools/etcd/etcd --data-dir=/data/etcd --name ${THIS_NAME} \
	--initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
	--advertise-client-urls http://0.0.0.0:2379 --listen-client-urls http://0.0.0.0:2379 \
	--initial-cluster ${CLUSTER} \
	--initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} \
	>> /data/etcd/log.log 2>&1 &

# For machine 4
#. /opt/tools/g.sh
THIS_NAME=${NAME_4}
THIS_IP=${HOST_4}
nohup /opt/tools/etcd/etcd --data-dir=/data/etcd --name ${THIS_NAME} \
--initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
--advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://${THIS_IP}:2379 \
--initial-cluster ${CLUSTER} \
--initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} \
>> /data/etcd/log.log 2>&1 &


#addmember
#. /opt/tools/g.sh
NAME_5=machine-5
HOST_5=172.17.165.231
/opt/tools/etcd/etcdctl --endpoints=${Endpoints} \
	member add ${NAME_5} \
	--peer-urls=http://${HOST_5}:2380

# should reset CLUSTER
#. /opt/tools/g.sh
THIS_NAME=${NAME_5}
THIS_IP=${HOST_5}

CLUSTER_STATE=existing
nohup /opt/tools/etcd/etcd --data-dir=/data/etcd --name ${THIS_NAME} \
--initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
--advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://${THIS_IP}:2379 \
--initial-cluster ${CLUSTER} \
--initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} \
>> /data/etcd/log.log 2>&1 &


#本地单节点 test
#
NAME_1=wxfhost
HOST_1=133.1.11.116
THIS_NAME=${NAME_1}
THIS_IP=${HOST_1}
CLUSTER=${NAME_1}=http://${HOST_1}:2380
CLUSTER_STATE=new
TOKEN=token-01
HOSTIP=${HOST_1}
Endpoints=http://${HOST_1}:2379
nohup /opt/tools/etcd/etcd --data-dir=/data/etcd --name ${THIS_NAME} \
	--initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://${THIS_IP}:2380 \
	--advertise-client-urls http://0.0.0.0:2379 --listen-client-urls http://0.0.0.0:2379 \
	--initial-cluster ${CLUSTER} \
	--initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} > /data/etcd/log.log 2>&1 &

docker stop registrator; docker rm registrator;\
docker run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock \
gliderlabs/registrator -ip $HOSTIP   etcd://$HOSTIP:2379/services

docker stop zerg; docker rm zerg; \
docker run -d  -P -v /data/logs/:/log --name zerg   unmerged/zerg

