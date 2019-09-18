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
		log.Printf("%s %s %d\n", ponger(count), msg, count)
		count++
		time.Sleep(time.Second)
	}
}

func ponger(i int) string {
	text := []rune("[-----------------------------------------]")
	if i%40+1 == 41-i%40 {
		text[i%40+1] = 'X'
		return string(text)
	}
	if i%40 == 0 {
		text[i%40+1] = '|'
		text[41-i%40] = '|'
		return string(text)
	}
	text[i%40+1] = '\\'
	text[41-i%40] = '/'
	return string(text)
}
