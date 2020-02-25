package main

import (
	"fmt"
	"time"
)

func main() {
	s := time.Tick(time.Second)

	thing := make([]byte, 500000000)

	for {
		select {
		case <-s:
			fmt.Printf("hey, thing is %v bytes\n", len(thing))
			thing = append(thing, 123)
		default:
			//fmt.Println("oh nothing")
		}
	}
}
