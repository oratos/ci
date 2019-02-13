package handlers_test

import (
	"encoding/json"
	"expvar"
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

var (
	testNamespacedCount *expvar.Map
	testClusterCount    *expvar.Int
)

func init() {
	testNamespacedCount = expvar.NewMap("test-namespaced")
	testClusterCount = expvar.NewInt("test-cluster")
}

var _ = Describe("Crosstalk Receiver", func() {
	BeforeEach(func() {
		testNamespacedCount.Init()
		testClusterCount.Set(0)
	})

	It("counts messages by the namespace in structured data", func() {
		s := tcpserver.New(
			":0",
			":0",
			":0",
			handlers.NewCountMessageHandler("crosstalk-test", testNamespacedCount, testClusterCount),
			tcpserver.Handler{"/metrics", expvar.Handler()},
		)
		defer s.Close()

		writer, err := net.Dial("tcp", s.SyslogAddr())
		Expect(err).ToNot(HaveOccurred())
		defer writer.Close()

		rfcLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: time.Now(),
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   []byte("crosstalk-test: this is a message for namespace-a"),
			StructuredData: []rfc5424.StructuredData{
				{
					ID: "kubernetes@47450",
					Parameters: []rfc5424.SDParam{
						{
							Name:  "namespace_name",
							Value: "foo",
						},
					},
				},
			},
		}

		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())

		c := readCounters(s.ApiAddr())

		Expect(c.Namespaced["foo"]).To(Equal(2))
		Expect(c.Cluster).To(Equal(2))
	})

	It("only counts messages intended for test", func() {
		s := tcpserver.New(
			":0",
			":0",
			":0",
			handlers.NewCountMessageHandler("crosstalk-test", testNamespacedCount, testClusterCount),
			tcpserver.Handler{"/metrics", expvar.Handler()},
		)
		defer s.Close()

		writer, err := net.Dial("tcp", s.SyslogAddr())
		Expect(err).ToNot(HaveOccurred())
		defer writer.Close()

		rfcLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: time.Now(),
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   []byte("crosstalk-test: this is a message for namespace-a"),
			StructuredData: []rfc5424.StructuredData{
				{
					ID: "kubernetes@47450",
					Parameters: []rfc5424.SDParam{
						{
							Name:  "namespace_name",
							Value: "foo",
						},
					},
				},
			},
		}

		rfcIgnoredLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: time.Now(),
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   []byte("this is a message for namespace-a"),
			StructuredData: []rfc5424.StructuredData{
				{
					ID: "kubernetes@47450",
					Parameters: []rfc5424.SDParam{
						{
							Name:  "namespace_name",
							Value: "foo",
						},
					},
				},
			},
		}
		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
		_, err = rfcIgnoredLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())

		c := readCounters(s.ApiAddr())

		Expect(c.Namespaced["foo"]).To(Equal(2))
		Expect(c.Cluster).To(Equal(2))
	})

	It("counts messages with non-matching namespace in unexpected count", func() {
		s := tcpserver.New(
			":0",
			":0",
			":0",
			handlers.NewCountMessageHandler("crosstalk-test", testNamespacedCount, testClusterCount),
			tcpserver.Handler{"/metrics", expvar.Handler()})

		defer s.Close()

		writer, err := net.Dial("tcp4", s.SyslogAddr())
		Expect(err).ToNot(HaveOccurred())

		rfcLog := rfc5424.Message{
			Priority:  rfc5424.Emergency,
			Timestamp: time.Now(),
			Hostname:  "some-host",
			AppName:   "some-app",
			ProcessID: "procID",
			MessageID: "msgID",
			Message:   []byte("crosstalk-test: this is a message for namespace-b"),
		}

		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())
		_, err = rfcLog.WriteTo(writer)
		Expect(err).ToNot(HaveOccurred())

		resp, err := http.Get(fmt.Sprintf("http://%s/metrics", s.ApiAddr()))
		Expect(err).ToNot(HaveOccurred())

		bytes, err := ioutil.ReadAll(resp.Body)
		Expect(err).ToNot(HaveOccurred())
		defer resp.Body.Close()
		c := syslogCounters{}

		err = json.Unmarshal(bytes, &c)
		Expect(err).ToNot(HaveOccurred())

		Expect(c.Namespaced).To(BeEmpty())
		Expect(c.Cluster).To(Equal(2))
	})

	It("shuts down the servers on Close()", func() {
		s := tcpserver.New(
			":0",
			":0",
			":0",
			handlers.NewCountMessageHandler("crosstalk-test", testNamespacedCount, testClusterCount),
			tcpserver.Handler{"/metrics", expvar.Handler()})

		_, err := net.Dial("tcp", s.SyslogAddr())
		Expect(err).ToNot(HaveOccurred())

		_, err = http.Get(fmt.Sprintf("http://%s/metrics", s.ApiAddr()))
		Expect(err).ToNot(HaveOccurred())

		s.Close()

		_, err = net.Dial("tcp", s.SyslogAddr())
		Expect(err).To(HaveOccurred())

		_, err = http.Get(fmt.Sprintf("http://%s/metrics", s.ApiAddr()))
		Expect(err).To(HaveOccurred())
	})
})

type syslogCounters struct {
	Namespaced map[string]int `json:"test-namespaced"`
	Cluster    int            `json:"test-cluster"`
}

func readCounters(addr string) syslogCounters {
	resp, err := http.Get(fmt.Sprintf("http://%s/metrics", addr))
	Expect(err).ToNot(HaveOccurred())

	bytes, err := ioutil.ReadAll(resp.Body)
	Expect(err).ToNot(HaveOccurred())
	defer resp.Body.Close()

	c := syslogCounters{}
	err = json.Unmarshal(bytes, &c)
	Expect(err).ToNot(HaveOccurred())
	return c
}
