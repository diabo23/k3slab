echo "
██╗  ██╗ █████╗  ██████╗
██║ ██╔╝██╔══██╗██╔════╝
█████╔╝ ███████║██║     
██╔═██╗ ██╔══██║██║     
██║  ██╗██║  ██║╚██████╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
"

export FALCON_IMAGE_TYPE=falcon-kac

#Get the Repository that hosts the Falcon KAC Image
export FALCON_IMAGE_REPO=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.repository')

#Get the latest available version of the Falcon KAC
export FALCON_IMAGE_TAG=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')

#Set the repositoruy of the Helm client
export FALCON_KAC_REPO=crowdstrike/falcon-kac

#Set the name of the Kubernetes Cluster; if Falcon KAC can autodiscover the cluster name, it overrides any cluster name you manually set.
export CLUSTER_NAME=se-k3s-cluster

#Installation of the Falcon KAC
helm upgrade --install falcon-kac $FALCON_KAC_REPO \
  -n falcon-kac --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set image.repository=$FALCON_IMAGE_REPO \
  --set image.tag=$FALCON_IMAGE_TAG \
  --set image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN \
  --set clusterName=$CLUSTER_NAME

#Wait until the Falcon KAC resources are up&running timeout is set to 60 seconds; uncomment the following section if you want to apply it.
#kubectl wait pod \
#--all \
#--for=condition=Ready \
#--namespace=falcon-kac \
#--timeout=60s
