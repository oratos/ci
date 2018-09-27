package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"code.cloudfoundry.org/rfc5424"
	"github.com/google/uuid"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"
)

const LatencyMetricName = "k8s_fluent_namespace_latency"

type LatencyLog struct {
	Timestamp time.Time `json:"timestamp"`
	RunID     string    `json:"run_id"`
	Sequence  int       `json:"sequence"`
}

type LatencyResponse struct {
	Series []LatencyMetric `json:"series"`
}

func NewLatencyResponse(runId string, latencies []time.Duration) LatencyResponse {
	lresp := LatencyResponse{}
	for i, latency := range latencies {
		sequenceTag := fmt.Sprintf("index: %d ", i)
		lresp.Series = append(lresp.Series, LatencyMetric{
			Metric: LatencyMetricName,
			Points: []time.Duration{latency},
			Type:   "gauge",
			Tags:   []string{runId, sequenceTag},
		})
	}
	return lresp

}

type LatencyMetric struct {
	Metric string          `json:"metric"`
	Points []time.Duration `json:"points"`
	Type   string          `json:"type"`
	Tags   []string        `json:"tags"`
}

type LatencyHandler struct {
	emitter        LogEmitter
	runDone        chan bool
	listMutex      *sync.Mutex
	latencies      []time.Duration
	runID          string
	timeout        time.Duration
	numLogsEmitted int
}

type LogEmitter interface {
	Emit(string)
}

func NewLatencyHandler(
	le LogEmitter,
	timeout time.Duration,
	numLogsEmitted int,
) *LatencyHandler {
	return &LatencyHandler{
		emitter:        le,
		runDone:        make(chan bool),
		listMutex:      &sync.Mutex{},
		timeout:        timeout,
		numLogsEmitted: numLogsEmitted,
	}
}

func (lh *LatencyHandler) MessageHandler() tcpserver.MessageHandler {
	return func(msg rfc5424.Message) {
		lh.listMutex.Lock()
		ll := LatencyLog{}
		err := json.Unmarshal(msg.Message, &ll)
		if err != nil {
			log.Panicf("invalid LatencyLog in syslog message")
		}
		lh.latencies = append(lh.latencies, msg.Timestamp.Sub(ll.Timestamp))
		lh.listMutex.Unlock()

		if len(lh.latencies) == lh.numLogsEmitted {
			lh.runDone <- true
		}
	}
}

func (lh *LatencyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "unsupported method", http.StatusNotFound)
	}

	lh.runID = uuid.New().String()
	for i := 0; i < lh.numLogsEmitted; i++ {
		ll := LatencyLog{
			Timestamp: time.Now(),
			RunID:     lh.runID,
			Sequence:  i,
		}

		lbyte, err := json.Marshal(&ll)
		if err != nil {
			log.Panic("failed to marshal latency log")
		}

		lh.emitter.Emit(string(lbyte))
	}

	timeout := time.NewTicker(lh.timeout)

	select {
	case <-lh.runDone:
		lh.listMutex.Lock()
		lresp := NewLatencyResponse(lh.runID, lh.latencies)
		bytes, err := json.Marshal(lresp)
		if err != nil {
			log.Panic("failed to marshal latency response")
		}
		w.Write(bytes)
		lh.listMutex.Unlock()
		return
	case <-timeout.C:
		http.Error(w, "test timed out", http.StatusRequestTimeout)
		return
	}
}
