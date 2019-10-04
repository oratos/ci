package main

import (
	"log"
	"os"
	"strings"
	"time"
)

func main() {
	msg := os.Getenv("MESSAGE")
	messageDelay := os.Getenv("MESSAGE_DELAY")
	var delay = time.Second

	if len(msg) == 0 {
		msg = "Log Message"
	}

	if len(messageDelay) != 0 {
		var err error
		delay, err = time.ParseDuration(messageDelay)
		if err != nil {
			log.Fatalf("Could not parse MESSAGE_DELAY: %s", err)
		}
	}

	count := 0
	for {
		log.Printf("%s %s %d\n", ponger(count), msg, count)
		count++
		time.Sleep(delay)
	}
}

const width int = 41

func ponger(i int) string {
	text := []rune("[" + strings.Repeat("-", width) + "]")

	text[(i+width/2)%width+1] = '*'
	text[width-(i+width/2)%width] = '*'
	if i%width+1 == width-i%width {
		text[i%width+1] = 'X'
		return string(text)
	}
	text[i%width+1] = '>'
	text[width-i%width] = '<'

	return string(text)
}
