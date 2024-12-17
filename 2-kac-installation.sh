echo "
██╗  ██╗ █████╗  ██████╗
██║ ██╔╝██╔══██╗██╔════╝
█████╔╝ ███████║██║     
██╔═██╗ ██╔══██║██║     
██║  ██╗██║  ██║╚██████╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
"

export FALCON_IMAGE_TYPE=falcon-kac

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