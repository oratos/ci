package tcpserver

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
)

type MessageHandler func(rfc5424.Message)

type tcpServer struct {
	syslogAddr     string
	apiAddr        string
	handleMsg      MessageHandler
	syslogListener net.Listener
	apiListener    net.Listener
	apiServer      http.Server
}

type Handler struct {
	Path    string
	Handler http.Handler
}

func New(
	syslogAddr string,
	apiAddr string,
	messageFunc MessageHandler,
	handlers ...Handler,
) *tcpServer {
	ts := &tcpServer{
		syslogAddr: syslogAddr,
		apiAddr:    apiAddr,
		handleMsg:  messageFunc,
	}

	ts.start(handlers...)
	return ts
}

func (t *tcpServer) start(handlers ...Handler) {
	log.Printf("Starting syslog server on: %s", t.syslogAddr)
	var err error
	t.syslogListener, err = net.Listen("tcp", t.syslogAddr)
	if err != nil {
		log.Fatal("failed to start up tcp server")
	}

	log.Printf("Starting metrics server on: %s", t.apiAddr)
	t.apiListener, err = net.Listen("tcp", t.apiAddr)
	if err != nil {
		log.Fatal("failed to start up tcp server")
	}

	mux := http.NewServeMux()
	for _, op := range handlers {
		mux.Handle(op.Path, op.Handler)
	}

	t.apiServer = http.Server{
		Addr:         t.apiAddr,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	go func() {
		t.apiServer.Serve(t.apiListener)
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

func (t *tcpServer) ApiAddr() string {
	return t.apiListener.Addr().String()
}

func (t *tcpServer) Close() error {
	err1 := t.syslogListener.Close()
	err2 := t.apiServer.Close()
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
