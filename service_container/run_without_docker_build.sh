set -x

rm -rf docker
mkdir docker
CGO_ENABLED=0 go build -o docker/service

docker run --rm -d -p 4128:4128  -v `pwd`/docker/:/app --name zerg alpine sh -c "/app/service --address :4128 >>/app/log.log 2>&1"

#for test
#go run example/single_machine_crawl.go --address :4128 --url http://baidu.com



#go run example/zerg_crawl.go --endpoints $Endpoint --url http://2017.ip138.com/ic.asp