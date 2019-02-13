package main

import (
	"expvar"
	"log"
	"net"
	"os"
	"os/signal"

	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/handlers"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"
)

var (
	namespacedCount        *expvar.Map
	webhookNamespacedCount *expvar.Map
	clusterCount           *expvar.Int
)

func init() {
	namespacedCount = expvar.NewMap("namespaced")
	clusterCount = expvar.NewInt("cluster")
	webhookNamespacedCount = expvar.NewMap("webhookNamespaced")
}

func main() {
	syslogPort := os.Getenv("SYSLOG_PORT")
	httpPort := os.Getenv("HTTP_PORT")
	metricsPort := os.Getenv("METRICS_PORT")
	message := os.Getenv("MESSAGE")

	if len(httpPort) == 0 {
		httpPort = "9898"
	}

	if len(syslogPort) == 0 || len(metricsPort) == 0 {
		log.Fatal("SYSLOG_PORT and METRICS_PORT are required")
	}

	if len(message) == 0 {
		message = "crosstalk-test"
	}

	server := tcpserver.New(
		net.JoinHostPort("", syslogPort),
		net.JoinHostPort("", httpPort),
		net.JoinHostPort("", metricsPort),
		handlers.NewCountMessageHandler(message, namespacedCount, clusterCount),
		tcpserver.Handler{
			Path:    "/metrics",
			Handler: expvar.Handler(),
		},
		tcpserver.Handler{
			Path:    "/webhook",
			Handler: handlers.NewWebhookHandler(webhookNamespacedCount),
		},
	)
	defer server.Close()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	<-c
}
