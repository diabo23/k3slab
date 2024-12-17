echo "
███████╗███████╗███╗   ██╗███████╗ ██████╗ ██████╗ 
██╔════╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗
███████╗█████╗  ██╔██╗ ██║███████╗██║   ██║██████╔╝
╚════██║██╔══╝  ██║╚██╗██║╚════██║██║   ██║██╔══██╗
███████║███████╗██║ ╚████║███████║╚██████╔╝██║  ██║
╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
"

export FALCON_IMAGE_TYPE=falcon-sensor

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

export FALCON_NAMESPACE=falcon-system
kubectl create namespace $FALCON_NAMESPACE
kubectl label ns --overwrite $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged

helm install falcon-sensor $FALCON_SENSOR_REPO \
  -n falcon-system --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set node.image.repository=$FALCON_IMAGE_REPO \
  --set node.image.tag=$FALCON_IMAGE_TAG \
  --set node.image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN


kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-system