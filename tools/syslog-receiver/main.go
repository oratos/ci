package main

import (
	"log"
	"net"
	"os"
	"os/signal"

	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/tcpserver"
)

func main() {
	syslogPort := os.Getenv("SYSLOG_PORT")
	metricsPort := os.Getenv("METRICS_PORT")

	if len(syslogPort) == 0 || len(metricsPort) == 0 {
		log.Fatal("SYSLOG_PORT and METRICS_PORT are required")
	}

	server := tcpserver.New(
		net.JoinHostPort("", syslogPort),
		net.JoinHostPort("", metricsPort),
	)
	defer server.Close()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	<-c
}
