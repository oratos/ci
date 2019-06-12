package main

import (
	"log"
	"net/http"
	"os"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	metricName := os.Getenv("METRIC_NAME")

	metricCounter := promauto.NewCounter(prometheus.CounterOpts{
		Name: metricName,
		Help: "This is for running e2e tests for the sink resources on kubernetes",
	})

	metricCounter.Add(105)

	http.Handle("/metrics", promhttp.Handler())
	log.Fatal(http.ListenAndServe(":2112", nil))
}
