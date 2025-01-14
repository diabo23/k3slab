echo "
██╗ █████╗  ██████╗    ███████╗ ██████╗███████╗     ██████╗██╗     ██╗    ████████╗ ██████╗  ██████╗ ██╗     
██║██╔══██╗██╔════╝    ██╔════╝██╔════╝██╔════╝    ██╔════╝██║     ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██║███████║██║         █████╗  ██║     ███████╗    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██╔══██║██║         ██╔══╝  ██║     ╚════██║    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██║  ██║╚██████╗    ██║     ╚██████╗███████║    ╚██████╗███████╗██║       ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝      ╚═════╝╚══════╝     ╚═════╝╚══════╝╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
"

#Set the CrowdStrike API Hostname (this is based on the Cloud Region)
if [ "$CROWDSTRIKE_CLOUD_ENV" == "us-1" ]
then
  FALCON_API_HOST=api.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "us-2" ]
then
  FALCON_API_HOST=api.us-2.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "eu-1" ]
then
  FALCON_API_HOST=api.eu-1.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "us-gov-1" ]
then
  FALCON_API_HOST=api.laggar.gcw.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "us-gov-2" ]
then
  FALCON_API_HOST=api.us-gov-2.crowdstrike.mil
else
  read -p "CrowdStrike Falcon API Hostname: " FALCON_API_HOST
fi

#Get the Token to perform request to the CrowdStrike API endpoints (the token expire 30 minutes after it's created)
export FALCON_API_TOKEN_URL=https://$FALCON_API_HOST/oauth2/token

export FALCON_API_TOKEN=$(curl -X POST --silent \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
    --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}" \
    "$FALCON_API_TOKEN_URL" | jq -r '.access_token')

#Get the FCS CLI Tool file name and version we want to download (in our case, the latest available version)
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

#Get a pre-signed URL to download the FCS CLI Tool file
export FALCON_FILES_DOWNLOAD_URL=https://$FALCON_API_HOST/csdownloads/entities/files/download/v1

export IAC_AUTH_URL=$(curl -X GET --silent -G \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data-urlencode "file_name=${IAC_FILE_NAME}" \
  --data-urlencode "file_version=${IAC_FILE_VERSION}" \
  "${FALCON_FILES_DOWNLOAD_URL}" | jq -r '.resources.download_url')

#Download the FCS CLI Tool file, unpack it and make it executable
wget -O fcs-cli-tool.tar.gz $IAC_AUTH_URL
tar -xvzf fcs-cli-tool.tar.gz
chmod +x fcs

#Create the FCS CLI Tool profile
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
