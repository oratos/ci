package tcpserver

import (
	"expvar"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
)

var (
	namespacedCount *expvar.Map
	clusterCount    *expvar.Int
)

func init() {
	namespacedCount = expvar.NewMap("namespaced")
	clusterCount = expvar.NewInt("cluster")
}

type tcpServer struct {
	syslogAddr      string
	metricsAddr     string
	handleMsg       func(rfc5424.Message)
	syslogListener  net.Listener
	metricsListener net.Listener
	metricsServer   http.Server
}

func New(syslogAddr, metricsAddr string) *tcpServer {
	// clear these for tests
	namespacedCount.Init()
	clusterCount.Set(0)
	ts := &tcpServer{
		syslogAddr:  syslogAddr,
		metricsAddr: metricsAddr,
		handleMsg:   countMessage,
	}

	ts.start()
	return ts
}

func (t *tcpServer) start() {
	log.Printf("Starting syslog server on: %s", t.syslogAddr)
	var err error
	t.syslogListener, err = net.Listen("tcp", t.syslogAddr)
	if err != nil {
		log.Fatal("failed to start up tcp server")
	}

	log.Printf("Starting metrics server on: %s", t.metricsAddr)
	t.metricsListener, err = net.Listen("tcp", t.metricsAddr)
	if err != nil {
		log.Fatal("failed to start up tcp server")
	}

	mux := http.NewServeMux()
	mux.Handle("/metrics", expvar.Handler())

	t.metricsServer = http.Server{
		Addr:         t.metricsAddr,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	go func() {
		t.metricsServer.Serve(t.metricsListener)
	}()

	go func() {
		for {
			conn, err := t.syslogListener.Accept()
			if err != nil {
				return
			}

			go t.handle(conn)
		}
	}()
}

func (t *tcpServer) SyslogAddr() string {
	return t.syslogListener.Addr().String()
}

func (t *tcpServer) MetricsAddr() string {
	return t.metricsListener.Addr().String()
}

func (t *tcpServer) Close() error {
	err1 := t.syslogListener.Close()
	err2 := t.metricsServer.Close()
	if err1 != nil || err2 != nil {
		return fmt.Errorf("error in cleanup up servers: %s %s", err1, err2)
	}
	return nil
}

func (t *tcpServer) handle(conn net.Conn) {
	defer conn.Close()

	var msg rfc5424.Message
	for {
		_, err := msg.ReadFrom(conn)
		if err != nil {
			return
		}

		t.handleMsg(msg)
	}
}

func countMessage(msg rfc5424.Message) {
	for _, sd := range msg.StructuredData {
		if sd.ID == "kubernetes@47450" {
			for _, param := range sd.Parameters {
				if param.Name == "namespace_name" {
					namespacedCount.Add(param.Value, 1)
					return
				}
			}
		}
	}

	clusterCount.Add(1)
}
