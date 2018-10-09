package main

import (
	"log"
	"os"
	"time"
)

func main() {
	msg := os.Getenv("MESSAGE")
	if len(msg) == 0 {
		msg = "Log Message"
	}

	count := 0
	for {
		log.Printf("%s %d\n", msg, count)
		count++
		time.Sleep(time.Second)
	}
}
