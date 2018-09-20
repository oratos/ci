package main

import (
	"log"
	"os"
)

func main() {
	st := os.Getenv("SEARCH_TEXT")
	p := os.Getenv("PORT")

	if len(st) == 0 {
		log.Fatal("SEARCH_TEXT is required")
	}

	if len(p) == 0 {
		log.Fatal("PORT is required")
	}

	server := tcpServer.New(st, p)
	server.Start()
	defer server.Close()
}
