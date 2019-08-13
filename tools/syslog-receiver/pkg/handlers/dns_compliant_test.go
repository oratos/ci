package handlers_test

import (
	"encoding/json"
	"expvar"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"code.cloudfoundry.org/rfc5424"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/handlers"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var (
	testDnsCompliantHostnameCount *expvar.Int
	testDnsNamespaced             *expvar.Map
	testDnsClusterCount           *expvar.Int
)

func init() {
	testDnsClusterCount = expvar.NewInt("cluster")
	testDnsNamespaced = expvar.NewMap("ignored-namespaced")
	testDnsCompliantHostnameCount = expvar.NewInt("dns-compliant-hostname")
}

var _ = Describe("DNS Compliant Handler", func() {
	BeforeEach(func() {
		testDnsCompliantHostnameCount.Set(0)
	})

	It("counts messages with DNS compliant hostnames", func() {
		s := tcpserver.New(
			":0",
			":0",
			":0",
			func(msg rfc5424.Message) {
				handlers.NewCountMessageHandler("crosstalk-test", testDnsNamespaced, testDnsClusterCount)(msg)
				handlers.NewDnsCompliantHandler("crosstalk-test", testDnsCompliantHostnameCount)(msg)
			},
			tcpserver.Handler{"/metrics", expvar.Handler()},
		)
		defer s.Close()

		writer := insecureTlsDial(s.SyslogAddr())
		defer writer.Close()

		validHostNames := []string{
			"validhostname",
			"valid-host-name",
			"valid.host.name",
			".valid.host.name",
		}

		invalidHostNames := []string{
			"invalid_host_name",
			"invalid-host-name-",
			"-invalid-host-name",
			"invalid-.host.name",
			"invalid.-host.name",
			"invalid-.-host.name",
		}

		allHosts := make([]string, 0, len(validHostNames)+len(invalidHostNames))
		allHosts = append(allHosts, validHostNames...)
		allHosts = append(allHosts, invalidHostNames...)

		for _, hostName := range allHosts {
			m := rfc5424.Message{
				Priority:  rfc5424.Emergency,
				Timestamp: time.Now(),
				Hostname:  hostName,
				AppName:   "some-app",
				ProcessID: "procID",
				MessageID: "msgID",
				Message:   []byte("crosstalk-test: this is a message"),
			}

			_, err := m.WriteTo(writer)
			Expect(err).ToNot(HaveOccurred())
		}

		Eventually(func() int {
			c := readDnsCounters(s.ApiAddr())
			return c.Cluster
		}, "3s", "1s").Should(Equal(len(allHosts)), "did not receive all messages")

		c := readDnsCounters(s.ApiAddr())

		Expect(c.DNSCompliant).To(Equal(len(validHostNames)), "did not receive correct number of dns compliant hostnames")
	})
})

type dnsCounters struct {
	Cluster      int `json:"cluster"`
	DNSCompliant int `json:"dns-compliant-hostname"`
}

func readDnsCounters(addr string) dnsCounters {
	resp, err := http.Get(fmt.Sprintf("http://%s/metrics", addr))
	Expect(err).ToNot(HaveOccurred())

	bytes, err := ioutil.ReadAll(resp.Body)
	Expect(err).ToNot(HaveOccurred())
	defer resp.Body.Close()

	c := dnsCounters{}
	err = json.Unmarshal(bytes, &c)
	Expect(err).ToNot(HaveOccurred())
	return c
}
