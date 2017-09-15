package main

import (
	"bytes"
	"crypto/tls"
	"flag"
	pb "github.com/wxf4150/zerg/protos"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"strconv"
	"time"
	"io"
	"compress/gzip"
	"bufio"
	"golang.org/x/net/html/charset"
	"golang.org/x/text/encoding/htmlindex"
)

var (
	address = flag.String("address", ":50051F", "服务器地址")
)

func main() {
	flag.Parse()

	lis, err := net.Listen("tcp", *address)
	if err != nil {
		log.Fatalf("无法绑定地址: %v", err)
	}

	log.Println("server start at:",*address)
	s := grpc.NewServer()
	pb.RegisterCrawlServer(s, &server{})
	s.Serve(lis)
}

type server struct {
	client *http.Client
}

func (s *server) Crawl(ctx context.Context, in *pb.CrawlRequest) (*pb.CrawlResponse, error) {
	return s.internalCrawl(in)
}

func (s *server) internalCrawl(in *pb.CrawlRequest) (*pb.CrawlResponse, error) {
	response := pb.CrawlResponse{}

	// 获取 http 连接
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{
		Transport: tr,
	}
	if in.Timeout > 0 {
		client.Timeout = time.Millisecond * time.Duration(in.Timeout)
	}

	// 根据不同的 method 类型，分别调用不同 HTTP 方法
	var err error
	var req *http.Request
	if in.Method == pb.Method_GET {
		req, err = http.NewRequest("GET", in.Url, nil)
	} else if in.Method == pb.Method_HEAD {
		req, err = http.NewRequest("HEAD", in.Url, nil)
	} else if in.Method == pb.Method_POST {
		buff := bytes.NewBufferString(in.PostBody)
		req, err = http.NewRequest("POST", in.Url, buff)
		req.Header.Add("Content-Type", in.BodyType)
		req.Header.Add("Content-Length", strconv.Itoa(len(in.PostBody)))
	}
	req.Header.Set("Accept-Encoding", "gzip") //使用gzip

	// 充填 header
	for _, header := range in.Header {
		req.Header.Add(header.Key, header.Value)
	}

	// 发送请求
	resp, err := client.Do(req)
	defer resp.Body.Close()
	if err != nil {
		return nil, err
	}

	// 只有当 method 不为 HEAD 时才读取页面内容
	var body []byte
	if in.Method != pb.Method_HEAD {
		// 读取页面内容
		var err error
		var reader io.ReadCloser
		switch resp.Header.Get("Content-Encoding") {
		case "gzip":
			//		fmt.Println("from gzip")
			reader, err = gzip.NewReader(resp.Body)
			if err != nil {
				return nil,err
			}
			defer reader.Close()
		default: reader = resp.Body
		}

		charset:="utf-8"
		if in.ExpectCharset!=""{
			charset=in.ExpectCharset
		}

		var body []byte
		//body, err = ioutil.ReadAll(resp.Body)
		if charset=="utf-8"{
			body, err = ioutil.ReadAll(reader)
		}else{
			utf_8reader,err1 :=decode(reader,charset)
			err=err1
			if err==nil{
				body, err = ioutil.ReadAll(utf_8reader)
			}
		}


		if err != nil {
			return nil, err
		}

		// 充填 response
		if !in.OnlyReturnMetadata {
			response.Content = string(body)
		}
	}

	// 充填 metadata
	response.Metadata = &pb.Metadata{}
	response.Metadata.Length = uint32(len(body))
	for key, vs := range resp.Header {
		for _, v := range vs {
			response.Metadata.Header = append(response.Metadata.Header, &pb.KV{
				Key:   key,
				Value: v,
			})
		}
	}
	response.Metadata.Status = resp.Status
	response.Metadata.StatusCode = int32(resp.StatusCode)

	return &response, nil
}


func detectContentCharset(body io.Reader) string {
	r := bufio.NewReader(body)
	if data, err := r.Peek(1024); err == nil {
		if _, name, ok := charset.DetermineEncoding(data, ""); ok {
			return name
		}
	}
	return "utf-8"
}

// Decode parses the HTML body on the specified encoding and
// returns the HTML Document.
func decode(body io.Reader, charset string) (io.Reader, error) {
	//log.Println("charset",charset)
	if charset=="auto" || charset == "" {
		charset = detectContentCharset(body)
	}
	//log.Println("charset",charset)
	e, err := htmlindex.Get(charset)
	if err != nil {
		return nil, err
	}

	if name, _ := htmlindex.Name(e); name != "utf-8" {
		body = e.NewDecoder().Reader(body)
	}

	return body, nil
}