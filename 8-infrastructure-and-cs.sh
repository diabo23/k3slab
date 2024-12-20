#The script needs 7 parameters given to it
# - The parameters could be given to it in an interactive way; this happens if you run the script with no parameters and you'll have to provide it one by one.
# - As an alternative, you can run the parameters giving the first five parameters (CID, CrowdStrike Cloud Region, API Client ID, Personal Repository and Docker Username) separated by a blank space; in this case the script will just ask you for the API Client Secret and Docker Password
#Given the sensitivity of the API Client Secret, while you enter it or while you paste it, the text won't appear in the terminal; once provided, just press Enter to pass it to the script.

export FALCON_CID
export CROWDSTRIKE_CLOUD_ENV
export FALCON_CLIENT_ID
export FALCON_CLIENT_SECRET
export MY_SHRA_REPO
export DOCKER_USERNAME
export DOCKER_PASSWORD

if [ $# -eq 5 ]
        then
                FALCON_CID=$1
                CROWDSTRIKE_CLOUD_ENV=$2
                FALCON_CLIENT_ID=$3
                MY_SHRA_REPO=$4
                DOCKER_USERNAME=$5
                read -s -p "CrowdStrike API Client Secret: " FALCON_CLIENT_SECRET
                read -s -p "CrowdStrike Docker Password: " DOCKER_PASSWORD
        else
                read -p "CrowdStrike CID: " FALCON_CID
                read -p "CrowdStrike Cloud Region: " CROWDSTRIKE_CLOUD_ENV
                read -p "CrowdStrike API Client Key: " FALCON_CLIENT_ID
                read -s -p "CrowdStrike API Client Secret: " FALCON_CLIENT_SECRET
                read -p "Private Registry Repo (to put CS Images): " MY_SHRA_REPO
                read -p "Docker Username: " DOCKER_USERNAME
                read -s -p "Docker Password: " DOCKER_PASSWORD
fi


echo "
██╗  ██╗██████╗ ███████╗    ██╗      █████╗ ██████╗     ██████╗ ██████╗ ███████╗██████╗  █████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
██║ ██╔╝╚════██╗██╔════╝    ██║     ██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
█████╔╝  █████╔╝███████╗    ██║     ███████║██████╔╝    ██████╔╝██████╔╝█████╗  ██████╔╝███████║██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║
██╔═██╗  ╚═══██╗╚════██║    ██║     ██╔══██║██╔══██╗    ██╔═══╝ ██╔══██╗██╔══╝  ██╔═══╝ ██╔══██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
██║  ██╗██████╔╝███████║    ███████╗██║  ██║██████╔╝    ██║     ██║  ██║███████╗██║     ██║  ██║██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
"

#Prevent Kernel update
export LINUX_IMAGE=$(dpkg --list | grep linux-image | head -1 | awk '{ print $2 }')
export LINUX_HEADERS=$(dpkg --list | grep linux-headers | head -1 | awk '{ print $2 }')
sudo apt-mark hold $LINUX_IMAGE $LINUX_HEADERS linux-image-aws linux-headers-aws

#######################
# DOCKER INSTALLATION #
#######################

#Uninstall all Docker conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg -y; done

#Fetches the latest version of the package list
sudo apt-get update

# Add Docker's official GPG key:
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#Install the Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Allow the use of Docker without sudo (exit or newgrp docker or reboot are required to activate the change)
sudo usermod -aG docker ${USER}

#####################
# HELM INSTALLATION #
#####################

sudo apt-get install -y snapd
sudo snap install helm --classic

################################################
# ADD CROWDSTRIKE FALCON HELM CHART REPOSITORY #
################################################

helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
helm repo update
helm repo list

###################
# JQ INSTALLATION #
###################

sudo apt-get install -y jq

#####################
# TREE INSTALLATION #
#####################

sudo apt-get install tree

####################
# K3S INSTALLATION #
####################

#K3S Deployment
curl -sfL https://get.k3s.io | sh -

#Allow the use of kubectl without sudo
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"

#Make the change persistent at reboot
echo export KUBECONFIG="/home/$USER/.kube/config" >> ~/.bash_profile

#Enable kubectl autocompletion
echo 'source <(kubectl completion bash)' >> ~/.bash_profile

#Apply the changes
source ~/.bash_profile

#Avoid a warning from Helm related to configuration file permissions
chmod 600 ~/.kube/config

#########################
# SET HOSTNAME AND FQDN #
#########################

#Set the hostname
sudo hostnamectl set-hostname ubuntu-box

#Set the FQDN
sudo bash -c 'echo "127.0.0.1 ubuntu-box.k3s.lab ubuntu-box" >>/etc/hosts'

#Set the SERVER_FQDN variable
export SERVER_FQDN=$(hostname -f)

##############################################################
# DOWNLOAD CROWDSTRIKE SCRIPT TO LIST AND DOWNLOAD RESOURCES #
##############################################################

curl -sSL -o falcon-container-sensor-pull.sh "https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/bash/containers/falcon-container-sensor-pull/falcon-container-sensor-pull.sh"
chmod +x falcon-container-sensor-pull.sh


echo "
 ██████╗███████╗    ██╗   ██╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██╗     ███████╗███████╗
██╔════╝██╔════╝    ██║   ██║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
██║     ███████╗    ██║   ██║███████║██████╔╝██║███████║██████╔╝██║     █████╗  ███████╗
██║     ╚════██║    ╚██╗ ██╔╝██╔══██║██╔══██╗██║██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
╚██████╗███████║     ╚████╔╝ ██║  ██║██║  ██║██║██║  ██║██████╔╝███████╗███████╗███████║
 ╚═════╝╚══════╝      ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝
"

#Get the username we'll use to connect to CrowdStrike Registry
export FALCON_ART_USERNAME=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --dump-credentials \
  | grep "CS Registry Username" | awk -F ": " '{print $2}')

#Get the password we'll use to connect to CrowdStrike Registry
export FALCON_ART_PASSWORD=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --dump-credentials \
  | grep "CS Registry Password" | awk -F ": " '{print $2}')

#Get the Token we'll use to pull images from CrowdStrike Registry (this Token does not expire)
export PARTIALPULLTOKEN=$(echo -n "$FALCON_ART_USERNAME:$FALCON_ART_PASSWORD" | base64 -w 0)
export FALCON_IMAGE_PULL_TOKEN=$(echo "{\"auths\":{\"registry.crowdstrike.com\":{\"auth\":\"$PARTIALPULLTOKEN\"}}}" | base64 -w 0)


echo "
 █████╗ ██╗     ██╗          ██████╗███████╗     ██████╗███╗   ██╗ █████╗ ██████╗ ██████╗ 
██╔══██╗██║     ██║         ██╔════╝██╔════╝    ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔══██╗
███████║██║     ██║         ██║     ███████╗    ██║     ██╔██╗ ██║███████║██████╔╝██████╔╝
██╔══██║██║     ██║         ██║     ╚════██║    ██║     ██║╚██╗██║██╔══██║██╔═══╝ ██╔═══╝ 
██║  ██║███████╗███████╗    ╚██████╗███████║    ╚██████╗██║ ╚████║██║  ██║██║     ██║     
╚═╝  ╚═╝╚══════╝╚══════╝     ╚═════╝╚══════╝     ╚═════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝     
"

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
export CLUSTER_NAME=se-agr-k3s

#Installation of the Falcon KAC
helm upgrade --install falcon-kac $FALCON_KAC_REPO \
  -n falcon-kac --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set image.repository=$FALCON_IMAGE_REPO \
  --set image.tag=$FALCON_IMAGE_TAG \
  --set image.registryConfigJSON=$FALCON_IMAGE_PULL_TOKEN \
  --set clusterName=$CLUSTER_NAME

#Wait until the Falcon KAC resources are up&running (timeout is set to 60 seconds)
kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-kac \
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
export CLUSTER_NAME=se-agr-k3s

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

#Wait until the IAR resources are up&running (timeout is set to 60 seconds)
kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-image-analyzer \
--timeout=60s


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
  --copy ${MY_SHRA_REPO} \
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
  --copy ${MY_SHRA_REPO} \
  --type falcon-registryassessmentexecutor \
  --version ${FALCON_SHRA_EX_VERSION}

#########################################################
# CREATION OF THE CONFIGURATION FILE FOR THE HELM CHART #
#########################################################

#CrowdStrike API Credentials
cat > values_override.yaml <<EOF
crowdstrikeConfig:
  clientID: "$FALCON_CLIENT_ID"
  clientSecret: "$FALCON_CLIENT_SECRET"

EOF

#Executor settings
cat >> values_override.yaml <<EOF
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

EOF

#Job Controller settings
cat >> values_override.yaml <<EOF
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

EOF

#Information related to the Registry to scan (type, credentials, involved repositories, schedule)
cat >> values_override.yaml <<EOF
registryConfigs:
  - type: dockerhub
    credentials:
      username: "$DOCKER_USERNAME"
      password: "$DOCKER_PASSWORD"
    allowedRepositories: ""
    host: "https://registry-1.docker.io"
    cronSchedule: "15 21 * * *"

EOF

#####################
# SHRA Installation #
#####################

helm upgrade --install -f /home/$USER/values_override.yaml \
    --create-namespace \
    --namespace falcon-self-hosted-registry-assessment \
    falcon-self-hosted-registry-assessment \
    crowdstrike/falcon-self-hosted-registry-assessment

#Wait until the SHRA resources are up&running (timeout is set to 60 seconds)
kubectl wait pod \
--all \
--for=condition=Ready \
--namespace=falcon-self-hosted-registry-assessment \
--timeout=60s


echo "
██╗ █████╗  ██████╗    ███████╗ ██████╗███████╗     ██████╗██╗     ██╗    ████████╗ ██████╗  ██████╗ ██╗     
██║██╔══██╗██╔════╝    ██╔════╝██╔════╝██╔════╝    ██╔════╝██║     ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██║███████║██║         █████╗  ██║     ███████╗    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██╔══██║██║         ██╔══╝  ██║     ╚════██║    ██║     ██║     ██║       ██║   ██║   ██║██║   ██║██║     
██║██║  ██║╚██████╗    ██║     ╚██████╗███████║    ╚██████╗███████╗██║       ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝      ╚═════╝╚══════╝     ╚═════╝╚══════╝╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
"

#Set the CrowdStrike API Hostname (this is based on the Cloud Region)
if [ "$CROWDSTRIKE_CLOUD_ENV" == "us-1" ]
then
  FALCON_API_HOST=api.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "us-2" ]
then
  FALCON_API_HOST=api.us-2.crowdstrike.com
elif [ "$CROWDSTRIKE_CLOUD_ENV" == "eu-1" ]
then
  FALCON_API_HOST=api.eu-1.crowdstrike.com
else
  read -p "CrowdStrike Falcon API Hostname: " FALCON_API_HOST
fi

#Get the Token to perform request to the CrowdStrike API endpoints (the token expire 30 minutes after it's created)
export FALCON_API_TOKEN_URL=https://$FALCON_API_HOST/oauth2/token

export FALCON_API_TOKEN=$(curl -X POST --silent \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
    --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}" \
    "$FALCON_API_TOKEN_URL" | jq -r '.access_token')

#Get the FCS CLI Tool file name and version we want to download (in our case, the latest available version)
export FALCON_FILE_ENUMERATION_URL=https://$FALCON_API_HOST/csdownloads/entities/files/enumerate/v1

export IAC_FILE_NAME=$(curl -X GET --silent \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  "${FALCON_FILE_ENUMERATION_URL}" \
  | jq -r 'last(.resources[] | select(.platform == "linux-amd64").file_name)')

export IAC_FILE_VERSION=$(curl -X GET --silent \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  "${FALCON_FILE_ENUMERATION_URL}" \
  | jq -r 'last(.resources[] | select(.platform == "linux-amd64").version)')

#Get a pre-signed URL to download the FCS CLI Tool file
export FALCON_FILES_DOWNLOAD_URL=https://$FALCON_API_HOST/csdownloads/entities/files/download/v1

export IAC_AUTH_URL=$(curl -X GET --silent -G \
  --header "Authorization: Bearer ${FALCON_API_TOKEN}" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data-urlencode "file_name=${IAC_FILE_NAME}" \
  --data-urlencode "file_version=${IAC_FILE_VERSION}" \
  "${FALCON_FILES_DOWNLOAD_URL}" | jq -r '.resources.download_url')

#Download the FCS CLI Tool file, unpack it and make it executable
wget -O fcs-cli-tool.tar.gz $IAC_AUTH_URL
tar -xvzf fcs-cli-tool.tar.gz
chmod +x fcs

#Create the FCS CLI Tool profile
mkdir -p ~/.crowdstrike

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