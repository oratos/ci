package tcpserver

import (
	"bytes"
	"expvar"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
)

var (
	expectedMsgCount   *expvar.Int
	unexpectedMsgCount *expvar.Int
)

func init() {
	expectedMsgCount = expvar.NewInt("expected")
	unexpectedMsgCount = expvar.NewInt("unexpected")
}

type tcpServer struct {
	listener  net.Listener
	metrics   http.Server
	namespace string
}

func New(namespace, port string) *tcpServer {
	expectedMsgCount.Set(0)
	unexpectedMsgCount.Set(0)

	l, err := net.Listen("tcp4", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatal("failed to start up tcp server")
	}

	mux := http.NewServeMux()
	mux.Handle("/metrics", expvar.Handler())

	s := http.Server{
		Addr:         ":6060",
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	return &tcpServer{
		listener:  l,
		metrics:   s,
		namespace: namespace,
	}
}

func (t *tcpServer) Start() {
	go func() {
		log.Println("Starting metrics server on 6060")
		t.metrics.ListenAndServe()
	}()

	for {
		conn, err := t.listener.Accept()
		if err != nil {
			log.Printf("Error accepting: %s", err)
			continue
		}
		log.Println("accepted connection")

		go t.handle(conn)
	}
}

func (t *tcpServer) URL() string {
	return t.listener.Addr().String()
}

func (t *tcpServer) Close() {
	t.listener.Close()
	t.metrics.Close()
}

func (t *tcpServer) handle(conn net.Conn) {
	defer conn.Close()

	var msg rfc5424.Message
	for {
		_, err := msg.ReadFrom(conn)
		if err != nil {
			if err == io.EOF {
				return
			}
			log.Printf("ReadFrom err: %s", err)
			return
		}

		if bytes.Contains(msg.Message, []byte(t.namespace)) {
			expectedMsgCount.Add(1)
		} else {
			unexpectedMsgCount.Add(1)
		}
	}
}
