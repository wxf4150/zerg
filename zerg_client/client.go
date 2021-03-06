package zerg_client

import (
	"errors"
	"github.com/wxf4150/load_balanced_service"
	pb "github.com/wxf4150/zerg/protos"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"strings"
	"log"
)

type ZergClient struct {
	endPoints   []string
	serviceName string
	lbService   load_balanced_service.LoadBalancedService
	clients     map[string]pb.CrawlClient
	conns       map[string]*grpc.ClientConn
	initialized bool
}

// endPoints: 逗号分隔的 etcd 接入点列表，每个接入点以 http:// 开始
func NewZergClient(endpoints string, servicename string) (*ZergClient, error) {
	// 解析 endPoints
	ep := strings.Split(endpoints, ",")
	if len(ep) == 0 {
		return nil, errors.New("无法解析endpoints")
	}

	zc := &ZergClient{
		endPoints:   ep,
		serviceName: servicename,
	}
	zc.clients = make(map[string]pb.CrawlClient)
	zc.conns = make(map[string]*grpc.ClientConn)
	err := zc.lbService.Connect(servicename, ep)
	if err != nil {
		return nil, err
	}
	zc.initialized = true
	return zc, nil
}

func (zc *ZergClient) Crawl(in *pb.CrawlRequest, opts ...grpc.CallOption) (*pb.CrawlResponse, error) {
	// 检查是否已经初始化
	if !zc.initialized {
		return nil, errors.New("ZergClient 没有初始化")
	}

	retrys:=0
	RETRY:
	node, err := zc.lbService.GetNode(true )
	if err != nil {
		return nil, err
	}

	if _, ok := zc.conns[node]; !ok {
		conn, err := grpc.Dial(node, grpc.WithInsecure(),grpc.WithDefaultCallOptions(grpc.MaxCallRecvMsgSize(1<<32)))
		if err != nil {
			return nil, err
		}
		zc.conns[node] = conn
		client := pb.NewCrawlClient(conn)
		zc.clients[node] = client
	}

	res,err:=zc.clients[node].Crawl(context.Background(), in, opts...)
	if err!=nil{
		if retrys<3 && strings.HasPrefix( err.Error(),"rpc error: code = Unavailable desc = grpc: the connection is unavailable"){
			log.Println("ZergClient: Unavailable grpc conn;nodeName:"+node+" url:"+in.Url)
			retrys++;
			goto RETRY
		}
		err=errors.New(err.Error()+"NodeName:"+node+" url:"+in.Url)
	}
	return res,err
}

func (zc *ZergClient) Close() {
	for _, v := range zc.conns {
		v.Close()
	}
	zc.initialized = false
}
