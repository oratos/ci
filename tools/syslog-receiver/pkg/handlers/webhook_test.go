package handlers_test

import (
	"net/http"
	"net/http/httptest"
	"strings"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/pivotal-cf/oratos-ci/tools/syslog-receiver/pkg/handlers"
)

var _ = Describe("Webhook", func() {
	BeforeEach(func() {
		testNamespacedCount.Init()
	})

	It("increments the counts by namespace", func() {
		h := handlers.NewWebhookHandler(testNamespacedCount)
		req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(sampleLogs))
		rec := httptest.NewRecorder()

		h.ServeHTTP(rec, req)

		Expect(rec.Code).To(Equal(http.StatusOK))
		Expect(testNamespacedCount.Get("my-namespace")).ToNot(BeNil())
		Expect(testNamespacedCount.Get("my-namespace").String()).To(Equal("2"))
		Expect(testNamespacedCount.Get("another-namespace")).ToNot(BeNil())
		Expect(testNamespacedCount.Get("another-namespace").String()).To(Equal("1"))
	})

	It("ignores non string namespaces", func() {
		h := handlers.NewWebhookHandler(testNamespacedCount)
		req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(nonStringNamespace))
		rec := httptest.NewRecorder()

		h.ServeHTTP(rec, req)

		Expect(rec.Code).To(Equal(http.StatusOK))
		Expect(testNamespacedCount.Get("12345")).To(BeNil())
	})
})

var (
	sampleLogs = `[
		{
			"date": 1549929688.058203,
			"log": "this is my log message",
			"kubernetes": {
				"pod_name": "pod-name",
				"namespace_name": "my-namespace",
				"pod_id": "pod-id",
				"host": "hostname",
				"container_name": "container-name",
				"docker_id": "docker-id"
			}
		},
		{
			"date": 1549929688.058203,
			"log": "this is my event message",
			"kubernetes": {
				"pod_name": "pod-name",
				"namespace_name": "my-namespace",
				"pod_id": "pod-id",
				"host": "hostname",
				"container_name": "container-name",
				"docker_id": "docker-id",
				"source_type": "k8s.event"
			}
		},
		{
			"date": 1549929688.058203,
			"log": "this is my log message",
			"kubernetes": {
				"pod_name": "pod-name",
				"namespace_name": "another-namespace",
				"pod_id": "pod-id",
				"host": "hostname",
				"container_name": "container-name",
				"docker_id": "docker-id"
			}
		}
	]`

	nonStringNamespace = `[
		{
			"date": 1549929688.058203,
			"log": "this is my log message",
			"kubernetes": {
				"pod_name": "pod-name",
				"namespace_name": 12345,
				"pod_id": "pod-id",
				"host": "hostname",
				"container_name": "container-name",
				"docker_id": "docker-id"
			}
		}
	]`
)
