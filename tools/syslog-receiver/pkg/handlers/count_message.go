package handlers

import (
	"expvar"
	"strings"

	"code.cloudfoundry.org/rfc5424"
	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/tcpserver"
)

func NewCountMessageHandler(
	message string,
	namespacedCount *expvar.Map,
	clusterCount *expvar.Int,
) tcpserver.MessageHandler {
	return func(msg rfc5424.Message) {
		if !strings.Contains(string(msg.Message), message) {
			return
		}

		clusterCount.Add(1)

		ns := namespace(msg)
		if ns != "" {
			namespacedCount.Add(ns, 1)
		}
	}
}

func namespace(msg rfc5424.Message) string {
	for _, sd := range msg.StructuredData {
		if sd.ID == "kubernetes@47450" {
			for _, param := range sd.Parameters {
				if param.Name == "namespace_name" {
					return param.Value
				}
			}
		}
	}

	return ""
}
