echo "
██╗  ██╗ █████╗  ██████╗
██║ ██╔╝██╔══██╗██╔════╝
█████╔╝ ███████║██║     
██╔═██╗ ██╔══██║██║     
██║  ██╗██║  ██║╚██████╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
"

export FALCON_IMAGE_TYPE=falcon-kac

<<'COMMENTS'
./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE
COMMENTS


export FALCON_IMAGE_REPO=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.repository')


export FALCON_IMAGE_TAG=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')


export FALCON_KAC_REPO=crowdstrike/falcon-kac
export CLUSTER_NAME=enc-k3s-1

helm upgrade --install falcon-kac $FALCON_KAC_REPO \
  -n falcon-kac --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set image.repository=$FALCON_IMAGE_REPO \
  --set image.tag=$FALCON_IMAGE_TAG \
  --set image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN \
  --set clusterName=$CLUSTER_NAME


kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-kac \
--timeout=60s


echo "
██╗ █████╗ ██████╗ 
██║██╔══██╗██╔══██╗
██║███████║██████╔╝
██║██╔══██║██╔══██╗
██║██║  ██║██║  ██║
╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
"

export FALCON_IMAGE_TYPE=falcon-imageanalyzer


<<'COMMENTS'
./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE
COMMENTS


export FALCON_IMAGE_REPO=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.repository')


export FALCON_IMAGE_TAG=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')


export FALCON_IAR_REPO=crowdstrike/falcon-image-analyzer


helm upgrade --install image-analyzer $FALCON_IAR_REPO \
  -n falcon-image-analyzer --create-namespace \
  --set deployment.enabled=true \
  --set crowdstrikeConfig.cid="$FALCON_CID" \
  --set crowdstrikeConfig.clusterName=enc-k3s-1 \
  --set crowdstrikeConfig.clientID=$FALCON_CLIENT_ID \
  --set crowdstrikeConfig.clientSecret=$FALCON_CLIENT_SECRET \
  --set image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN \
  --set crowdstrikeConfig.agentRegion=$CROWDSTRIKE_CLOUD_ENV \
  --set image.repository="$FALCON_IMAGE_REPO" \
  --set image.tag="$FALCON_IMAGE_TAG"


kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-image-analyzer \
--timeout=60s


echo "
███████╗███████╗███╗   ██╗███████╗ ██████╗ ██████╗ 
██╔════╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗
███████╗█████╗  ██╔██╗ ██║███████╗██║   ██║██████╔╝
╚════██║██╔══╝  ██║╚██╗██║╚════██║██║   ██║██╔══██╗
███████║███████╗██║ ╚████║███████║╚██████╔╝██║  ██║
╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
"

export FALCON_IMAGE_TYPE=falcon-sensor


<<'COMMENTS'
./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE
COMMENTS


export FALCON_IMAGE_REPO=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.repository')


export FALCON_IMAGE_TAG=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')


export FALCON_SENSOR_REPO=crowdstrike/falcon-sensor


helm upgrade --install falcon-sensor $FALCON_SENSOR_REPO \
  -n falcon-system --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set node.image.repository=$FALCON_IMAGE_REPO \
  --set node.image.tag=$FALCON_IMAGE_TAG \
  --set node.image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN


kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-system \
--timeout=60s


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
wget -O ~/fcs-cli-tool.tar.gz $IAC_AUTH_URL

#Unpack the archive
tar -xvzf ~/fcs-cli-tool.tar.gz

#Make the file executable
chmod +x ~/fcs

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

echo ""