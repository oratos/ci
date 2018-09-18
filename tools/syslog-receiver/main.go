package main

import (
	"log"
	"os"
	"os/signal"

	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/tcpserver"
)

func main() {
	p := os.Getenv("PORT")

	if len(p) == 0 {
		log.Fatal("PORT is required")
	}

	server := tcpserver.New(p)
	defer server.Close()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	<-c
}
