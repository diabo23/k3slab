echo "
██╗ █████╗  ██████╗    ███████╗ ██████╗███████╗     ██████╗██╗     ██╗    ████████╗ ██████╗  ██████╗ ██╗     
██║██╔══██╗██╔════╝    ██╔════╝██╔════╝██╔════╝    ██╔════╝██║     ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██║███████║██║         █████╗  ██║     ███████╗    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██╔══██║██║         ██╔══╝  ██║     ╚════██║    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██║  ██║╚██████╗    ██║     ╚██████╗███████║    ╚██████╗███████╗██║       ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝      ╚═════╝╚══════╝     ╚═════╝╚══════╝╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
"

#Variables specific to download components via API (in our case, FCS CLI Tool in IAC Section)
export FALCON_API_HOST=api.crowdstrike.com
export FALCON_API_TOKEN_URL=https://$FALCON_API_HOST/oauth2/token

#Get an API Access Token and assign it to a variable
export FALCON_API_TOKEN=$(curl -X POST --silent \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
    --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}" \
    "$FALCON_API_TOKEN_URL" | jq -r '.access_token')

export FALCON_FILE_ENUMERATION_URL=https://$FALCON_API_HOST/csdownloads/entities/files/enumerate/v1

#Assign the file_name variable
export IAC_FILE_NAME=$(curl -X GET --silent \
	--header "Authorization: Bearer ${FALCON_API_TOKEN}" \
	--header "Accept: application/json" \
	--header "Content-Type: application/json" \
	"${FALCON_FILE_ENUMERATION_URL}" \
	| jq -r 'last(.resources[] | select(.platform == "linux-amd64").file_name)')

#Assign the version variable
export IAC_FILE_VERSION=$(curl -X GET --silent \
	--header "Authorization: Bearer ${FALCON_API_TOKEN}" \
	--header "Accept: application/json" \
	--header "Content-Type: application/json" \
	"${FALCON_FILE_ENUMERATION_URL}" \
	| jq -r 'last(.resources[] | select(.platform == "linux-amd64").version)')

#Get a pre-signed URL to download the file
export FALCON_FILES_DOWNLOAD_URL=https://$FALCON_API_HOST/csdownloads/entities/files/download/v1

export IAC_AUTH_URL=$(curl -X GET --silent -G \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data-urlencode "file_name=${IAC_FILE_NAME}" \
  --data-urlencode "file_version=${IAC_FILE_VERSION}" \
  "${FALCON_FILES_DOWNLOAD_URL}" | jq -r '.resources.download_url')

#Download the FCS CLI Tool
wget -O fcs-cli-tool.tar.gz $IAC_AUTH_URL

#Unpack the archive
tar -xvzf fcs-cli-tool.tar.gz

#Make the file executable
chmod +x fcs

#Create the folder to store the FCS CLI Profile
mkdir -p ~/.crowdstrike

#Create the FCS CLI Profile
cat > ~/.crowdstrike/fcs_profiles.json <<EOF
{
    "default": {
        "falcon_region": "$CROWDSTRIKE_CLOUD_ENV",
        "client_id": "$FALCON_CLIENT_ID",
        "client_secret": "$FALCON_CLIENT_SECRET"
   }
}
EOF