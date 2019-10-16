API_KEY=$(vault read -format json "secret/toolsmith-api-key" | jq .data.key -r )
cmd=${1:-}
case "$cmd" in
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