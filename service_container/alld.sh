set -x

docker run --rm -d -p 4128:4128  -v `pwd`/docker/:/app --name zerg  sh -c "/app/service --address :4128 >>/app/log.log 2>&1"

#
