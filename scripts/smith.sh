API_KEY=$(vault read -format json "secret/toolsmith" | jq .data.api_key -r )
GCP_KEY="$(vault read --field=gcp_key "secret/toolsmith" )"
cmd=${1:-}
case "$cmd" in
    create)
        VERSION=${2:-1_5}
        curl "https://environments.toolsmiths.cf-app.com/v1/custom_gcp/pks/create" -d "{\"api_token\": \"${API_KEY}\", \"sa_gcp_key\": ${GCP_KEY}, \"version\": \"us_${VERSION}\"}" -H "Content-Type: application/json" -v | jq .
        ;;
    list)
        curl "https://environments.toolsmiths.cf-app.com/v1/custom_gcp/pks/list?api_token=${API_KEY}" | jq .
        ;;
    get-info)
        curl "https://environments.toolsmiths.cf-app.com/v1/custom_gcp/pks/metadata?api_token=${API_KEY}&name=${2}" | jq .
        ;;
    destroy)
        curl "https://environments.toolsmiths.cf-app.com/v1/custom_gcp/pks/destroy" -d "{\"api_token\": \"${API_KEY}\", \"name\": \"${2}\"}" -H "Content-Type: application/json" -v | jq .
        ;;
esac
