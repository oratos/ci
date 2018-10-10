
function generate_values {
    echo "$VALUES"
}

function service_account {
    lpass show "$LASTPASS_VAULT_GCS_SERVICE_ACCOUNT" --notes
}

function cert {
    lpass show "$LASTPASS_X509_PATH" | \
        sed -n "/^-----BEGIN CERTIFICATE-----$/,/-----END CERTIFICATE-----/p"
}

function key {
    lpass show "$LASTPASS_X509_PATH" | \
        sed -n "/^-----BEGIN PRIVATE KEY-----$/,/-----END PRIVATE KEY-----/p"
}

function install_vault {
    echo
    echo
    echo INSTALLING VAULT
    echo

    kubectl create namespace "$NAMESPACE_NAME"

    sa_file="$(mktemp)"
    cert_file="$(mktemp)"
    key_file="$(mktemp)"
    service_account > "$sa_file"
    cert > "$cert_file"
    key > "$key_file"

    kubectl create secret generic vault-gcs-service-account \
        --from-file=key.json="$sa_file" \
        --namespace "$NAMESPACE_NAME"
    kubectl create secret tls vault-tls \
        --cert "$cert_file" \
        --key "$key_file" \
        --namespace "$NAMESPACE_NAME"

    rm "$sa_file"
    rm "$cert_file"
    rm "$key_file"

    helm repo add incubator \
        http://storage.googleapis.com/kubernetes-charts-incubator
    helm install incubator/vault \
        --name vault \
        --values <(generate_values) \
        --namespace "$NAMESPACE_NAME"
    kubectl apply --filename ./nginx.yml
}

function upgrade_vault {
    echo
    echo
    echo UPGRADING VAULT
    echo

    kubectl delete secret vault-gcs-service-account \
        --namespace "$NAMESPACE_NAME" || true
    kubectl delete secret vault-tls \
        --namespace "$NAMESPACE_NAME" || true

    sa_file="$(mktemp)"
    cert_file="$(mktemp)"
    key_file="$(mktemp)"
    service_account > "$sa_file"
    cert > "$cert_file"
    key > "$key_file"

    kubectl create secret generic vault-gcs-service-account \
        --from-file=key.json="$sa_file" \
        --namespace "$NAMESPACE_NAME"
    kubectl create secret tls vault-tls \
        --cert "$cert_file" \
        --key "$key_file" \
        --namespace "$NAMESPACE_NAME"

    rm "$sa_file"
    rm "$cert_file"
    rm "$key_file"

    helm upgrade vault incubator/vault --values <(generate_values)
    kubectl apply --filename ./nginx.yml
}

function loadbalancer_ip {
    kubectl get ingress vault-vault \
        --output jsonpath='{ .status.loadBalancer.ingress[0].ip }' \
        --namespace "$NAMESPACE_NAME"
}

function poll_loadbalancer_ip {
    echo
    echo
    echo POLLING FOR LOAD BALANCER
    echo

    local lb_ip
    while true; do
        lb_ip="$(loadbalancer_ip)"
        if [ "$lb_ip" != "" ]; then
            break
        fi
        echo -n .
        sleep 2
    done

    echo
    echo "Load Balancer IP: $lb_ip"
    echo
    echo Configure the DNS for your External URL to point to this IP.
    echo
}
