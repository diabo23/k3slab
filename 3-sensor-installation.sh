echo "
███████╗███████╗███╗   ██╗███████╗ ██████╗ ██████╗ 
██╔════╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗
███████╗█████╗  ██╔██╗ ██║███████╗██║   ██║██████╔╝
╚════██║██╔══╝  ██║╚██╗██║╚════██║██║   ██║██╔══██╗
███████║███████╗██║ ╚████║███████║╚██████╔╝██║  ██║
╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
"

export FALCON_IMAGE_TYPE=falcon-sensor

#Get the Repository that hosts the Falcon Sensor Image
export FALCON_IMAGE_REPO=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.repository')

#Get the latest available version of the Falcon Sensor
export FALCON_IMAGE_TAG=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')

#Set the repositoruy of the Helm client
export FALCON_SENSOR_REPO=crowdstrike/falcon-sensor

#Create the namespace where Falcon Sensor resources will be put and set the security context (Falcon Sensor will run in a privileged POD)
export FALCON_NAMESPACE=falcon-system
kubectl create namespace $FALCON_NAMESPACE
kubectl label ns --overwrite $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged

#Install the Falcon Sensor
helm upgrade --install falcon-sensor $FALCON_SENSOR_REPO \
  -n falcon-system --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set node.image.repository=$FALCON_IMAGE_REPO \
  --set node.image.tag=$FALCON_IMAGE_TAG \
  --set node.image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN

#Wait until the Falcon Sensor resources are up&running (timeout is set to 60 seconds)
kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-system \
--timeout=60s