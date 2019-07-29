package handlers

import (
	"expvar"
	"regexp"
	"strings"

	"code.cloudfoundry.org/rfc5424"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"
)

var invalidHostnameCharacter = regexp.MustCompile(`[^a-z0-9-.]|(^|\.)-|-(\.|$)`)

func NewDnsCompliantHandler(
	message string,
	dnsCompliantHostnameCount *expvar.Int,
) tcpserver.MessageHandler {
	return func(msg rfc5424.Message) {
		if !strings.Contains(string(msg.Message), message) {
			return
		}

		if invalidHostnameCharacter.MatchString(msg.Hostname) {
			return
		}

		dnsCompliantHostnameCount.Add(1)
	}
}
