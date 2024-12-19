echo "
███████╗██╗  ██╗██████╗  █████╗ 
██╔════╝██║  ██║██╔══██╗██╔══██╗
███████╗███████║██████╔╝███████║
╚════██║██╔══██║██╔══██╗██╔══██║
███████║██║  ██║██║  ██║██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
"

#The script needs 3 parameters given to it
# - The parameters could be given to it in an interactive way; this happens if you run the script with no parameters and you'll have to provide it one by one.
# - As an alternative, you can run the parameters giving the first two parameters (Personal Repository and Docker Username); in this case the script will just ask you for the Docker Password
#Given the sensitivity of the Docker Password, while you enter it or while you paste it, the text won't appear in the terminal; once provided, just press Enter to pass it to the script.

export MY_SHRA_REPO
export DOCKER_USERNAME
export DOCKER_PASSWORD


if [ $# -eq 2 ]
        then
                MY_SHRA_REPO=$1
                DOCKER_USERNAME=$2
                read -s -p "Docker Password: " DOCKER_PASSWORD
        else
                read -p "Private Registry Repo (to put CS Images): " MY_SHRA_REPO
                read -p "Docker Username: " DOCKER_USERNAME
                read -s -p "Docker Password: " DOCKER_PASSWORD
fi


kubectl create namespace falcon-self-hosted-registry-assessment


docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
export ENCODED_LOGIN=$(cat ~/.docker/config.json | base64 -w0)


export FALCON_IMAGE_TYPE=falcon-jobcontroller


export FALCON_SHRA_JC_VERSION=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')


#Copy the SHRA Job Controller image to Docker Hub via the pull sensor script
./falcon-container-sensor-pull.sh \
  --client-id ${FALCON_CLIENT_ID} \
  --client-secret ${FALCON_CLIENT_SECRET} \
  --copy ${MY_SHRA_REPO} \
  --type $FALCON_IMAGE_TYPE \
  --version ${FALCON_SHRA_JC_VERSION}


export FALCON_IMAGE_TYPE=falcon-registryassessmentexecutor


export FALCON_SHRA_EX_VERSION=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --list-tags \
  -t $FALCON_IMAGE_TYPE \
  | jq -r '.tags | last')


#Copy the SHRA Executor image to Docker Hub  via the pull sensor script
./falcon-container-sensor-pull.sh \
  --client-id ${FALCON_CLIENT_ID} \
  --client-secret ${FALCON_CLIENT_SECRET} \
  --copy ${MY_SHRA_REPO} \
  --type falcon-registryassessmentexecutor \
  --version ${FALCON_SHRA_EX_VERSION}


cat > values_override.yaml <<EOF
crowdstrikeConfig:
  clientID: "$FALCON_CLIENT_ID"
  clientSecret: "$FALCON_CLIENT_SECRET"

executor:
  image:
    registry: "$MY_SHRA_REPO"
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
jobController:
  image:
    registry: "$MY_SHRA_REPO"
    repository: "falcon-jobcontroller"
    tag: "$FALCON_SHRA_JC_VERSION"
    registryConfigJSON: "$ENCODED_LOGIN"
  dbStorage:
    create: true
    size: 1Gi
    storageClass: "local-path"
    accessModes:
      - ReadWriteOnce
registryConfigs:
  - type: dockerhub
    credentials:
      username: "$DOCKER_USERNAME"
      password: "$DOCKER_PASSWORD"
    allowedRepositories: ""
    host: "https://registry-1.docker.io"
    cronSchedule: "45 22 * * *"
EOF


helm upgrade --install -f /home/$USER/values_override.yaml \
    --create-namespace \
    --namespace falcon-self-hosted-registry-assessment \
    falcon-self-hosted-registry-assessment \
    crowdstrike/falcon-self-hosted-registry-assessment


kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-self-hosted-registry-assessment \
--timeout=60s
