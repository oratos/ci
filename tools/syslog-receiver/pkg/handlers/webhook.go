package handlers

import (
	"encoding/json"
	"expvar"
	"log"
	"net/http"
)

type WebhookHandler struct {
	counts *expvar.Map
}

func NewWebhookHandler(
	counts *expvar.Map,
) *WebhookHandler {
	return &WebhookHandler{
		counts: counts,
	}
}

func (h *WebhookHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var msg []webhookMessage
	if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	for _, m := range msg {
		ns, ok := m.Kubernetes["namespace_name"]
		if !ok {
			continue
		}

		nsStr, ok := ns.(string)
		if !ok {
			continue
		}

		h.counts.Add(nsStr, 1)
	}
}

type webhookMessage struct {
	Kubernetes map[string]interface{} `json:"kubernetes"`
}
