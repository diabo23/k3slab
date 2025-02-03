echo "
███████╗██╗  ██╗██████╗  █████╗ 
██╔════╝██║  ██║██╔══██╗██╔══██╗
███████╗███████║██████╔╝███████║
╚════██║██╔══██║██╔══██╗██╔══██║
███████║██║  ██║██║  ██║██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
"

#The script uses the same Docker Hub registry both for copying CrowdStrike images related to the SHRA and for performing the images assessment.
#In case you want to use two Docker Hub registers, one for copying CrowdStrike images and one for image assessment, simply adapt the script to your needs.
#Similarly, the script can be adapted to use registries other than Docker Hub.

#The script needs 3 parameters given to it
# - The parameters could be given to it in an interactive way; this happens if you run the script with no parameters and you'll have to provide it one by one.
# - As an alternative, you can run the parameters giving the first two parameters (Personal Registry, Docker Username, Docker Password/Token).

export MY_SHRA_REGISTRY
export DOCKER_USERNAME
export DOCKER_PASSWORD

if [ $# -eq 3 ]
        then
                MY_SHRA_REGISTRY=$1
                DOCKER_USERNAME=$2
                DOCKER_PASSWORD=$3
        else
                read -p "Private Registry (to put CS Images): " MY_SHRA_REGISTRY
                read -p "Docker Username: " DOCKER_USERNAME
                read -p "Docker Password: " DOCKER_PASSWORD
fi

#Create the namespace where the Falcon SHRA resources will be put
kubectl create namespace falcon-self-hosted-registry-assessment

#Get the encoded Docker login information that we'll use to pull images from this repository
docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
export ENCODED_LOGIN=$(cat ~/.docker/config.json | base64 -w0)


################################################################
# JOB CONTROLLER - COPY IMAGE IN THE PERSONAL PRIVATE REGISTRY #
################################################################

#Get the latest available version of the Job Controller (one of the PODs of Falcon SHRA)
export FALCON_IMAGE_TYPE=falcon-jobcontroller

export FALCON_SHRA_JC_VERSION=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')

#Copy the Job Controller image to our private Docker Hub registry
./falcon-container-sensor-pull.sh \
  --client-id ${FALCON_CLIENT_ID} \
  --client-secret ${FALCON_CLIENT_SECRET} \
  --copy ${MY_SHRA_REGISTRY} \
  --type $FALCON_IMAGE_TYPE \
  --version ${FALCON_SHRA_JC_VERSION}

##########################################################
# EXECUTOR - COPY IMAGE IN THE PERSONAL PRIVATE REGISTRY #
##########################################################

#Get the latest available version of the Executor (one of the PODs of Falcon SHRA)
export FALCON_IMAGE_TYPE=falcon-registryassessmentexecutor

export FALCON_SHRA_EX_VERSION=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')

#Copy the Executor image to our private Docker Hub registry
./falcon-container-sensor-pull.sh \
  --client-id ${FALCON_CLIENT_ID} \
  --client-secret ${FALCON_CLIENT_SECRET} \
  --copy ${MY_SHRA_REGISTRY} \
  --type falcon-registryassessmentexecutor \
  --version ${FALCON_SHRA_EX_VERSION}

#########################################################
# CREATION OF THE CONFIGURATION FILE FOR THE HELM CHART #
#########################################################

#CrowdStrike API Credentials
cat > /home/$USER/values_override.yaml <<EOF
crowdstrikeConfig:
  clientID: "$FALCON_CLIENT_ID"
  clientSecret: "$FALCON_CLIENT_SECRET"

EOF

#Executor settings
cat >> /home/$USER/values_override.yaml <<EOF
executor:
  image:
    registry: "$MY_SHRA_REGISTRY"
    repository: "falcon-registryassessmentexecutor"
    tag: "$FALCON_SHRA_EX_VERSION"
    registryConfigJSON: "$ENCODED_LOGIN"
  dbStorage:
    create: true
    size: 1Gi
    storageClass: "local-path"
    accessModes:
      - ReadWriteOnce
  assessmentStorage:
    type: "PVC"
    size: 5Gi
    pvc:
      create: true
      storageClass: "local-path"
      accessModes:
        - ReadWriteOnce

EOF

#Job Controller settings
cat >> /home/$USER/values_override.yaml <<EOF
jobController:
  image:
    registry: "$MY_SHRA_REGISTRY"
    repository: "falcon-jobcontroller"
    tag: "$FALCON_SHRA_JC_VERSION"
    registryConfigJSON: "$ENCODED_LOGIN"
  dbStorage:
    create: true
    size: 1Gi
    storageClass: "local-path"
    accessModes:
      - ReadWriteOnce

EOF

#Information related to the Registry to scan (type, credentials, involved repositories, schedule)
#In the example, the scheduling will perform an analysis every hour, 15 minutes after the hour (e.g. at 10:15, 11:15, 12:15, etc.)
cat >> /home/$USER/values_override.yaml <<EOF
registryConfigs:
  - type: dockerhub
    credentials:
      username: "$DOCKER_USERNAME"
      password: "$DOCKER_PASSWORD"
    allowedRepositories: ""
    host: "https://registry-1.docker.io"
    cronSchedule: "15 * * * *"

EOF

#####################
# SHRA Installation #
#####################

helm upgrade --install -f /home/$USER/values_override.yaml \
    --create-namespace \
    --namespace falcon-self-hosted-registry-assessment \
    falcon-self-hosted-registry-assessment \
    crowdstrike/falcon-self-hosted-registry-assessment

#Wait until the SHRA resources are up&running, timeout is set to 60 seconds; uncomment the following section if you want to apply the check.
#kubectl wait pod \
#--all \
#--for=condition=Ready \
#--namespace=falcon-self-hosted-registry-assessment \
#--timeout=60s
