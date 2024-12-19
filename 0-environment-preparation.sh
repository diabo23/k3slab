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