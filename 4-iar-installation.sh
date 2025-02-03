echo "
██╗ █████╗ ██████╗ 
██║██╔══██╗██╔══██╗
██║███████║██████╔╝
██║██╔══██║██╔══██╗
██║██║  ██║██║  ██║
╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
"

export FALCON_IMAGE_TYPE=falcon-imageanalyzer

#Get the Repository that hosts the IAR Image
export FALCON_IMAGE_REPO=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.repository')

#Get the latest available version of the IAR
export FALCON_IMAGE_TAG=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')

#Set the repositoruy of the Helm client
export FALCON_IAR_REPO=crowdstrike/falcon-image-analyzer

#Set the name of the Kubernetes Cluste
export CLUSTER_NAME=se-k3s-cluster

#Installation of the IAR
helm upgrade --install image-analyzer $FALCON_IAR_REPO \
  -n falcon-image-analyzer --create-namespace \
  --set deployment.enabled=true \
  --set crowdstrikeConfig.cid="$FALCON_CID" \
  --set crowdstrikeConfig.clusterName=$CLUSTER_NAME \
  --set crowdstrikeConfig.clientID=$FALCON_CLIENT_ID \
  --set crowdstrikeConfig.clientSecret=$FALCON_CLIENT_SECRET \
  --set image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN \
  --set crowdstrikeConfig.agentRegion=$CROWDSTRIKE_CLOUD_ENV \
  --set image.repository="$FALCON_IMAGE_REPO" \
  --set image.tag="$FALCON_IMAGE_TAG"

#Wait until the IAR resources are up&running, timeout is set to 60 seconds; uncomment the following section if you want to apply the check.
#kubectl wait pod \
#--all \
#--for=condition=Ready \
#--namespace=falcon-image-analyzer \
#--timeout=60s
