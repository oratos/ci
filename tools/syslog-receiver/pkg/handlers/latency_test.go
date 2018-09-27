package handlers_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/handlers"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const numLogsEmitted = 9

var _ = Describe("Latency Receiver", func() {
	Describe("Emitting logs", func() {
		It("emits configured number of logs when latency endpoint is posted to", func() {
			se := &spyLogEmitter{}
			latencyHandler := handlers.NewLatencyHandler(
				se,
				10*time.Second,
				numLogsEmitted,
			)

			s := tcpserver.New(
				":0",
				":0",
				latencyHandler.MessageHandler(),
				tcpserver.Handler{
					"/latency_test",
					latencyHandler,
				},
			)
			defer s.Close()

			writeSyslog(s.SyslogAddr())
			http.Get(fmt.Sprintf("http://%s/latency_test", s.ApiAddr()))

			Expect(se.Messages).ToNot(HaveLen(0))
			Expect(se.Messages).To(HaveLen(numLogsEmitted))
		})

		It("emits logs as json in expected format", func() {
			se := &spyLogEmitter{}
			latencyHandler := handlers.NewLatencyHandler(
				se,
				10*time.Second,
				numLogsEmitted,
			)

			s := tcpserver.New(
				":0",
				":0",
				latencyHandler.MessageHandler(),
				tcpserver.Handler{
					"/latency_test",
					latencyHandler,
				},
			)
			defer s.Close()

			writeSyslog(s.SyslogAddr())
			http.Get(fmt.Sprintf("http://%s/latency_test", s.ApiAddr()))

			Expect(se.Messages).ToNot(HaveLen(0))

			var err error
			ll := handlers.LatencyLog{}
			for _, msg := range se.Messages {
				err = json.Unmarshal([]byte(msg), &ll)
				Expect(err).ToNot(HaveOccurred())

				Expect(ll.Timestamp).To(BeTemporally("<=", time.Now()))
				Expect(ll.RunID).ToNot(BeEmpty())
			}
		})

		It("validates the http method", func() {
			se := &spyLogEmitter{}
			latencyHandler := handlers.NewLatencyHandler(
				se,
				10*time.Second,
				numLogsEmitted,
			)

			s := tcpserver.New(
				":0",
				":0",
				latencyHandler.MessageHandler(),
				tcpserver.Handler{
					"/latency_test",
					latencyHandler,
				},
			)
			defer s.Close()

			writeSyslog(s.SyslogAddr())
			url := fmt.Sprintf("http://%s/latency_test", s.ApiAddr())
			resp, err := http.Post(
				url,
				"application/text",
				bytes.NewBuffer([]byte("")),
			)
			Expect(err).ToNot(HaveOccurred())

			Expect(resp.StatusCode).To(Equal(http.StatusNotFound))
		})
	})

	Describe("Receiving logs", func() {
		It("times out waiting for all of the logs to be received", func() {
			se := &spyLogEmitter{}
			latencyHandler := handlers.NewLatencyHandler(se, time.Second, numLogsEmitted)

			s := tcpserver.New(
				":0",
				":0",
				latencyHandler.MessageHandler(),
				tcpserver.Handler{
					"/latency_test",
					latencyHandler,
				},
			)
			defer s.Close()

			resp, err := http.Get(fmt.Sprintf("http://%s/latency_test", s.ApiAddr()))

			Expect(err).ToNot(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(http.StatusRequestTimeout))
		})

		It("returns latencies for logs emitted", func() {
			se := &spyLogEmitter{}
			latencyHandler := handlers.NewLatencyHandler(se, 10*time.Second, numLogsEmitted)

			s := tcpserver.New(
				":0",
				":0",
				latencyHandler.MessageHandler(),
				tcpserver.Handler{
					"/latency_test",
					latencyHandler,
				},
			)
			defer s.Close()

			writeSyslog(s.SyslogAddr())
			resp, err := http.Get(fmt.Sprintf("http://%s/latency_test", s.ApiAddr()))
			Expect(err).ToNot(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(http.StatusOK))

			htmlData, err := ioutil.ReadAll(resp.Body)
			resp.Body.Close()
			Expect(err).ToNot(HaveOccurred())

			lresp := handlers.LatencyResponse{}
			err = json.Unmarshal(htmlData, &lresp)

			Expect(err).ToNot(HaveOccurred())
			Expect(lresp.Series).To(HaveLen(numLogsEmitted))
		})

		It("returns latencies in the expected format", func() {
			se := &spyLogEmitter{}
			latencyHandler := handlers.NewLatencyHandler(
				se,
				10*time.Second,
				numLogsEmitted,
			)

			s := tcpserver.New(
				":0",
				":0",
				latencyHandler.MessageHandler(),
				tcpserver.Handler{
					"/latency_test",
					latencyHandler,
				},
			)
			defer s.Close()

			fluentTime := time.Now()
			sinkTime := fluentTime.Add(2 * time.Second)
			writeSyslogTimes(s.SyslogAddr(), fluentTime, sinkTime)
			resp, err := http.Get(fmt.Sprintf("http://%s/latency_test", s.ApiAddr()))
			Expect(err).ToNot(HaveOccurred())

			htmlData, err := ioutil.ReadAll(resp.Body)
			resp.Body.Close()
			Expect(err).ToNot(HaveOccurred())

			lresp := handlers.LatencyResponse{}
			err = json.Unmarshal(htmlData, &lresp)
			Expect(err).ToNot(HaveOccurred())

			Expect(lresp.Series).To(HaveLen(numLogsEmitted))
			Expect(lresp.Series[0].Metric).To(Equal(handlers.LatencyMetricName))
			Expect(lresp.Series[0].Points).To(HaveLen(1))

			// Have to do a range check on time because we seem to be losing
			// precison
			Expect(lresp.Series[0].Points[0]).To(BeNumerically(">", 1999500*time.Microsecond))
			Expect(lresp.Series[0].Points[0]).To(BeNumerically("<", 2000500*time.Microsecond))

			Expect(lresp.Series[0].Type).To(Equal("gauge"))
			Expect(lresp.Series[0].Tags).To(HaveLen(2))
			Expect(lresp.Series[0].Tags[0]).ToNot(BeEmpty())
			Expect(lresp.Series[0].Tags[1]).To(ContainSubstring("index:"))
		})
	})
})

type spyLogEmitter struct {
	Messages []string
}

func (se *spyLogEmitter) Emit(message string) {
	se.Messages = append(se.Messages, message)
}

func writeSyslog(syslogAddr string) {
	writeSyslogTimes(syslogAddr, time.Now(), time.Now())
}

func writeSyslogTimes(syslogAddr string, fluentTime, sinkTime time.Time) {
	writer, err := net.Dial("tcp", syslogAddr)
	Expect(err).ToNot(HaveOccurred())
	defer writer.Close()

	for i := 0; i < numLogsEmitted; i++ {
		ll := handlers.LatencyLog{
			Timestamp: fluentTime,
			RunID:     "some-run-id",
			Sequence:  i,
		}

		msg, err := json.Marshal(&ll)
		Expect(err).ToNot(HaveOccurred())

		rfcLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: sinkTime,
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   msg,
		}

		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
	}
}
