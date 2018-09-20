package tcpserver_test

import (
	"encoding/json"
	"io/ioutil"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/tcpserver"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Tcpserver", func() {
	It("shuts down the servers on Close()", func() {
		s := tcpserver.New("something", "6061")
		go s.Start()

		_, err := net.Dial("tcp4", s.URL())
		Expect(err).ToNot(HaveOccurred())

		_, err = http.Get("http://localhost:6060/metrics")
		Expect(err).ToNot(HaveOccurred())

		s.Close()

		_, err = net.Dial("tcp4", s.URL())
		Expect(err).To(HaveOccurred())

		_, err = http.Get("http://localhost:6060/metrics")
		Expect(err).To(HaveOccurred())
	})

	It("counts the messages with matching namespace in expected count", func() {
		s := tcpserver.New("namespace-a", "6061")
		go s.Start()
		defer s.Close()

		writer, err := net.Dial("tcp4", s.URL())
		Expect(err).ToNot(HaveOccurred())
		defer func() {
			writer.Close()
		}()

		rfcLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: time.Now(),
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   []byte("this is a message for namespace-a"),
		}

		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())

		resp, err := http.Get("http://localhost:6060/metrics")
		Expect(err).ToNot(HaveOccurred())

		bytes, err := ioutil.ReadAll(resp.Body)
		Expect(err).ToNot(HaveOccurred())
		defer resp.Body.Close()
		c := syslogCounters{}

		err = json.Unmarshal(bytes, &c)
		Expect(err).ToNot(HaveOccurred())

		Expect(c.Expected).To(Equal(2))
		Expect(c.Unexpected).To(Equal(0))
	})

	It("counts messages with non-matching namespace in unexpected count", func() {
		s := tcpserver.New("namespace-a", "6061")
		go s.Start()
		defer s.Close()

		writer, err := net.Dial("tcp4", s.URL())
		Expect(err).ToNot(HaveOccurred())

		rfcLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: time.Now(),
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   []byte("this is a message for namespace-b"),
		}

		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())

		resp, err := http.Get("http://localhost:6060/metrics")
		Expect(err).ToNot(HaveOccurred())

		bytes, err := ioutil.ReadAll(resp.Body)
		Expect(err).ToNot(HaveOccurred())
		defer resp.Body.Close()
		c := syslogCounters{}

		err = json.Unmarshal(bytes, &c)
		Expect(err).ToNot(HaveOccurred())

		Expect(c.Expected).To(Equal(0))
		Expect(c.Unexpected).To(Equal(2))
	})
})

type syslogCounters struct {
	Expected   int `json:"expected"`
	Unexpected int `json:"unexpected"`
}
