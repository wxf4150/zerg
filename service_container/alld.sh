#build

#CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/service
#docker build -t unmerged/zerg -f bin/zerg_Dockerfile bin/
rsync -auv service_container/bin/service kfmtest:/opt/tools/

set -x
docker stop zerg

#etcd  should start first

#registrator service
docker   stop registrator & docker   rm registrator
#HOSTIP=133.1.11.116
#HOSTIP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'` \

. /opt/tools/setip.sh && \
docker run -d --name=registrator --net=host --volume=/var/run/docker.sock:/tmp/docker.sock \
  gliderlabs/registrator -ip $HOSTIP   etcd://0.0.0.0:2379/services


docker  stop zerg
docker run --rm -d -P -v /data/logs/:/log --name zerg   unmerged/zerg
#docker run --rm -d -v `pwd`/bin/log/:/log --name zerg unmerged/zerg  sh -c "./service --address :4128 >>/log/zerg.log 2>&1"
#docker run --rm -d -p 4128:4128  -v `pwd`/bin/:/app --name zerg alpine  sh -c "/app/service --address :4128 >>/app/log.log 2>&1"


