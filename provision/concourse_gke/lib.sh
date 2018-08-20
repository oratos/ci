
function cert {
    lpass show "$LASTPASS_X509_PATH" | \
        sed -n "/^-----BEGIN CERTIFICATE-----$/,/-----END CERTIFICATE-----/p"
}

function key {
    lpass show "$LASTPASS_X509_PATH" | \
        sed -n "/^-----BEGIN PRIVATE KEY-----$/,/-----END PRIVATE KEY-----/p"
}

function install_concourse {
    echo
    echo
    echo INSTALLING CONCOURSE
    echo

    cert_file="$(mktemp)"
    key_file="$(mktemp)"
    cert > "$cert_file"
    key > "$key_file"

    kubectl create namespace "$NAMESPACE_NAME"
    kubectl create secret tls concourse-web-tls \
        --cert "$cert_file" \
        --key "$key_file" \
        --namespace "$NAMESPACE_NAME"
    helm install stable/concourse \
        --name concourse \
        --values <(generate_values) \
        --namespace "$NAMESPACE_NAME"

    rm "$cert_file"
    rm "$key_file"
}

function loadbalancer_ip {
    kubectl get ingress concourse-web \
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

function generate_values {
    echo "$VALUES"
    secrets
}

function secrets {
    lpass show --notes "$LASTPASS_SECRETS_PATH"
}

function upgrade_concourse {
    echo
    echo
    echo UPGRADING CONCOURSE
    echo
    helm upgrade concourse stable/concourse --values <(generate_values)
}
