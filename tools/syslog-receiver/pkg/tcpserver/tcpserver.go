package tcpserver

import (
	"crypto/tls"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
)

type MessageHandler func(rfc5424.Message)

type tcpServer struct {
	syslogAddr      string
	httpAddr        string
	metricsAddr     string
	handleMsg       MessageHandler
	syslogListener  net.Listener
	metricsListener net.Listener
	httpListener    net.Listener
	metricsConfig   http.Server
	httpServer      http.Server
	tlsConfig       *tls.Config
}

type Handler struct {
	Path    string
	Handler http.Handler
}

func New(
	syslogAddr string,
	httpAddr string,
	metricsAddr string,
	messageFunc MessageHandler,
	metricsHandler Handler,
	httpHandlers ...Handler,
) *tcpServer {
	cer, err := tls.LoadX509KeyPair("localhost.crt", "localhost.key")
	if err != nil {
		log.Fatalf("Failed to load testing key and certificate: %q", err)
	}

	ts := &tcpServer{
		syslogAddr:  syslogAddr,
		httpAddr:    httpAddr,
		metricsAddr: metricsAddr,
		handleMsg:   messageFunc,
		tlsConfig:   &tls.Config{Certificates: []tls.Certificate{cer}},
	}

	ts.start(metricsHandler, httpHandlers...)
	return ts
}

func (t *tcpServer) start(metricsHandler Handler, handlers ...Handler) {
	log.Printf("Starting syslog server on: %s", t.syslogAddr)
	var err error
	t.syslogListener, err = tls.Listen("tcp", t.syslogAddr, t.tlsConfig)
	if err != nil {
		log.Fatalf("failed to start up tcp server: %s", err)
	}

	log.Printf("Starting metrics server on: %s", t.metricsAddr)
	t.metricsListener, err = net.Listen("tcp", t.metricsAddr)
	if err != nil {
		log.Fatalf("failed to start up metrics server: %s", err)
	}

	log.Printf("Starting HTTP server on: %s", t.httpAddr)
	t.httpListener, err = tls.Listen("tcp", t.httpAddr, t.tlsConfig)
	if err != nil {
		log.Fatalf("failed to start up http server: %s", err)
	}

	metricsMux := http.NewServeMux()
	metricsMux.Handle(metricsHandler.Path, metricsHandler.Handler)

	httpMux := http.NewServeMux()
	for _, op := range handlers {
		httpMux.Handle(op.Path, op.Handler)
	}

	t.httpServer = http.Server{
		Addr:         t.httpAddr,
		Handler:      httpMux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		TLSConfig:    t.tlsConfig,
	}

	t.metricsConfig = http.Server{
		Addr:         t.metricsAddr,
		Handler:      metricsMux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	go t.httpServer.Serve(t.httpListener)
	go t.metricsConfig.Serve(t.metricsListener)
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
	return t.metricsListener.Addr().String()
}

func (t *tcpServer) Close() error {
	err1 := t.syslogListener.Close()
	err2 := t.metricsConfig.Close()
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
