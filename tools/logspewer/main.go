package main

import (
	"log"
	"time"
)

func main() {

	count := 0
	for {
		log.Printf("Log Message %d\n", count)
		count++
		time.Sleep(time.Second)
	}
}
