echo "
██╗ █████╗ ██████╗ 
██║██╔══██╗██╔══██╗
██║███████║██████╔╝
██║██╔══██║██╔══██╗
██║██║  ██║██║  ██║
╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
"

export FALCON_IMAGE_TYPE=falcon-imageanalyzer

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
  --set crowdstrikeConfig.clusterName=enc-k3s-2 \
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