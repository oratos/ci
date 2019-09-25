package main

import (
	"log"
	"os"
	"strings"
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
		time.Sleep(time.Millisecond * 100)
	}
}

const width int = 41

func ponger(i int) string {
	text := []rune("[" + strings.Repeat("-", width) + "]")
	if i%width+1 == width-i%width {
		text[i%width+1] = 'X'
		return string(text)
	}
	text[i%width+1] = '>'
	text[width-i%width] = '<'
	return string(text)
}
