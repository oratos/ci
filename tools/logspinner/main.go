package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type logRequest struct {
	Times int    `json:"times"`
	Msg   string `json:"msg"`
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		decoder := json.NewDecoder(r.Body)
		var req logRequest
		err := decoder.Decode(&req)
		if err != nil {
			w.WriteHeader(400)
			w.Write([]byte(fmt.Sprintf("Failed to unmarshal body, should be like { \"msg\": \"message\", \"times\": 10 }, err=%s", err.Error())))
			return
		}
		if req.Times <= 0 || req.Msg == "" {
			w.WriteHeader(400)
			w.Write([]byte("Failed to get good properties, should be like { \"msg\": \"message\", \"times\": 10 }"))
			return
		}
		for i := 0; i < req.Times; i++ {
			log.Printf("%s  %d", req.Msg, i)
		}
		w.Write([]byte("OK!"))
	})
	http.ListenAndServe(":8080", nil)
}
