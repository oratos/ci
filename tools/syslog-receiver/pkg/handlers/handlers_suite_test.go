package handlers_test

import (
	"crypto/tls"
	"io"
	"log"
	"os"
	"os/exec"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestHandlers(t *testing.T) {
	log.SetOutput(GinkgoWriter)
	RegisterFailHandler(Fail)
	RunSpecs(t, "Handlers Suite")
}

var _ = BeforeSuite(func() {
	keyGenCmd := exec.Command("openssl", "genrsa", "-out", "localhost.key", "2048")
	Expect(keyGenCmd.Run()).To(Succeed())

	certGenCmd := exec.Command("openssl", "req", "-new", "-subj", "/CN=localhost", "-x509", "-sha256", "-key", "localhost.key", "-out", "localhost.crt", "-days", "3650")
	Expect(certGenCmd.Run()).To(Succeed())
})

var _ = AfterSuite(func() {
	os.Remove("localhost.key")
	os.Remove("localhost.crt")
})

func insecureTlsDial(addr string) io.WriteCloser {
	writer, err := tls.Dial("tcp", addr, &tls.Config{
		InsecureSkipVerify: true,
	})
	Expect(err).ToNot(HaveOccurred())

	return writer
}
