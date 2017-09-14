package main

import (
	"flag"
	pb "github.com/wxf4150/zerg/protos"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"log"
)

var (
	address = flag.String("address", ":50051", "服务器地址")
	url     = flag.String("url", "", "URL")
	method  = flag.String("method", "GET", "HTTP 请求类型：GET HEAD POST")
)

func main() {
	flag.Parse()

	// 得到 CrawlClient
	conn, err := grpc.Dial(*address, grpc.WithInsecure())
	if err != nil {
		log.Fatal(err)
	}
	client := pb.NewCrawlClient(conn)

	log.Printf("开始抓取")
	request := pb.CrawlRequest{
		Url:     *url,
		Timeout: 10000,
		Method:  pb.Method(pb.Method_value[*method]),
		ExpectCharset:"",  //163.com gbk.   default:utf-8
	}
	response, err := client.Crawl(context.Background(), &request)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("抓取完毕")
	log.Printf("%+v", response.Metadata)
	log.Printf("%d", len(response.Content))
	log.Printf("%s", response.Content)
}
