package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"time"

	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/handlers"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"
)

func main() {
	syslogPort := os.Getenv("SYSLOG_PORT")
	apiPort := os.Getenv("API_PORT")

	if len(syslogPort) == 0 || len(apiPort) == 0 {
		log.Fatal("SYSLOG_PORT and API_PORT are required")
	}

	lh := handlers.NewLatencyHandler(
		stdOutLogEmitter{},
		10*time.Second,
		15,
	)

	server := tcpserver.New(
		net.JoinHostPort("", syslogPort),
		":0",
		net.JoinHostPort("", apiPort),
		lh.MessageHandler(),
		tcpserver.Handler{
			Path:    "/latency",
			Handler: lh,
		},
	)
	defer server.Close()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	<-c
}

type stdOutLogEmitter struct{}

func (s stdOutLogEmitter) Emit(msg string) {
	fmt.Println(msg)
}
