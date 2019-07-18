# input validation

RELEASE_VERSION=$1

(
    echo CRITICAL HIGH IMAGE
    for image in $(gcloud beta container images list --repository gcr.io/cf-pks-observability1/released-images/$1 | tail -n +2); do
        SHA=$(gcloud container images list-tags $image --format='get(digest)')
        CRITICAL=$(gcloud beta container images describe $image@$SHA --show-package-vulnerability --format json | jq '.package_vulnerability_summary.vulnerabilities.CRITICAL | length ')
        HIGH=$(gcloud beta container images describe $image@$SHA --show-package-vulnerability --format json | jq '.package_vulnerability_summary.vulnerabilities.HIGH | length ')
        echo $CRITICAL $HIGH https://$image@$SHA
    done
) | column -t
