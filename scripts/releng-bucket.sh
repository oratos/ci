
vault read --field=gcp_key secret/releng > /tmp/key.json
gcloud auth activate-service-account --key-file /tmp/key.json