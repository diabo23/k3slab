echo "
██╗ █████╗  ██████╗    ███████╗ ██████╗███████╗     ██████╗██╗     ██╗    ████████╗ ██████╗  ██████╗ ██╗     
██║██╔══██╗██╔════╝    ██╔════╝██╔════╝██╔════╝    ██╔════╝██║     ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██║███████║██║         █████╗  ██║     ███████╗    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██╔══██║██║         ██╔══╝  ██║     ╚════██║    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██║  ██║╚██████╗    ██║     ╚██████╗███████║    ╚██████╗███████╗██║       ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝      ╚═════╝╚══════╝     ╚═════╝╚══════╝╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
"

if [ "$CROWDSTRIKE_CLOUD_ENV" == "us-1" ]
then
  FALCON_API_HOST=api.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "us-2" ]
then
  FALCON_API_HOST=api.us-2.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "eu-1" ]
then
  FALCON_API_HOST=api.eu-1.crowdstrike.com
else
  read -p "CrowdStrike Falcon API Hostname: " FALCON_API_HOST
fi

#US-1: api.crowdstrike.com
#US-2: api.us-2.crowdstrike.com
#EU-1: api.eu-1.crowdstrike.com

export FALCON_API_TOKEN_URL=https://$FALCON_API_HOST/oauth2/token

export FALCON_API_TOKEN=$(curl -X POST --silent \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
    --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}" \
    "$FALCON_API_TOKEN_URL" | jq -r '.access_token')

export FALCON_FILE_ENUMERATION_URL=https://$FALCON_API_HOST/csdownloads/entities/files/enumerate/v1

export IAC_FILE_NAME=$(curl -X GET --silent \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  "${FALCON_FILE_ENUMERATION_URL}" \
  | jq -r 'last(.resources[] | select(.platform == "linux-amd64").file_name)')

export IAC_FILE_VERSION=$(curl -X GET --silent \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  "${FALCON_FILE_ENUMERATION_URL}" \
  | jq -r 'last(.resources[] | select(.platform == "linux-amd64").version)')

export FALCON_FILES_DOWNLOAD_URL=https://$FALCON_API_HOST/csdownloads/entities/files/download/v1

export IAC_AUTH_URL=$(curl -X GET --silent -G \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data-urlencode "file_name=${IAC_FILE_NAME}" \
  --data-urlencode "file_version=${IAC_FILE_VERSION}" \
  "${FALCON_FILES_DOWNLOAD_URL}" | jq -r '.resources.download_url')

wget -O fcs-cli-tool.tar.gz $IAC_AUTH_URL
tar -xvzf fcs-cli-tool.tar.gz
chmod +x fcs

mkdir -p ~/.crowdstrike

cat > ~/.crowdstrike/fcs_profiles.json <<EOF
{
    "default": {
        "falcon_region": "$CROWDSTRIKE_CLOUD_ENV",
        "client_id": "$FALCON_CLIENT_ID",
        "client_secret": "$FALCON_CLIENT_SECRET"
   }
}
EOF