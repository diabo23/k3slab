#To redirect the output to a log file while maintaining the output on screen, launch the script adding: 2>&1 | tee script-1.log
#. ./1-environment-preparation.sh 2>&1 | tee script-1.log
#The example is using source so variables could be called outside the script for troubleshooting or operation reasons


echo "
██╗  ██╗██████╗ ███████╗    ██╗      █████╗ ██████╗     ██████╗ ██████╗ ███████╗██████╗  █████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
██║ ██╔╝╚════██╗██╔════╝    ██║     ██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
█████╔╝  █████╔╝███████╗    ██║     ███████║██████╔╝    ██████╔╝██████╔╝█████╗  ██████╔╝███████║██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║
██╔═██╗  ╚═══██╗╚════██║    ██║     ██╔══██║██╔══██╗    ██╔═══╝ ██╔══██╗██╔══╝  ██╔═══╝ ██╔══██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
██║  ██╗██████╔╝███████║    ███████╗██║  ██║██████╔╝    ██║     ██║  ██║███████╗██║     ██║  ██║██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
"

echo "*** Step a-00 *********************************************************************************************************************"
echo "*** Copy the time from hw clock to sys clock to prevent issues in case of sync problems (to avoid Repository is not valid yet) ****"

sudo hwclock --hctosys

echo "*** Step a-01 *********************************************************************************************************************"
echo "*** Prevent Kernel update *********************************************************************************************************"

#Prevent Kernel update
export LINUX_IMAGE=$(dpkg --list | grep linux-image | head -1 | awk '{ print $2 }')
export LINUX_HEADERS=$(dpkg --list | grep linux-headers | head -1 | awk '{ print $2 }')
sudo apt-mark hold $LINUX_IMAGE $LINUX_HEADERS linux-image-aws linux-headers-aws

echo "*** Step a-02 *********************************************************************************************************************"
echo "*** Docker Installation ***********************************************************************************************************"

#######################
# DOCKER INSTALLATION #
#######################

echo "*** Step a-02-1 *********************************************************************************************************************"
echo "*** Uninstall all Docker conflicting packages ***************************************************************************************"

#Uninstall all Docker conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg -y; done

echo "*** Step a-02-2 *********************************************************************************************************************"
echo "*** Fetch the latest version of the package list ************************************************************************************"

#Fetch the latest version of the package list
sudo apt-get update

echo "*** Step a-02-3 *********************************************************************************************************************"
echo "*** Add Docker's official GPG key ***************************************************************************************************"

# Add Docker's official GPG key:
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "*** Step a-02-4 *********************************************************************************************************************"
echo "*** Add the repository to APT sources ***********************************************************************************************"

# Add the repository to APT sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo "*** Step a-02-5 *********************************************************************************************************************"
echo "*** Install the Docker packages *****************************************************************************************************"

#Install the Docker packages
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "*** Step a-02-6 *********************************************************************************************************************"
echo "*** Allow the use of Docker without sudo ********************************************************************************************"

#Allow the use of Docker without sudo (exit or newgrp docker or reboot are required to activate the change)
sudo usermod -aG docker ${USER}

echo "*** Step a-02-7 *********************************************************************************************************************"
echo "*** Helm installation ***************************************************************************************************************"

#####################
# HELM INSTALLATION #
#####################

sudo apt-get install -y snapd
sudo snap install helm --classic

echo "*** Step a-03 ***********************************************************************************************************************"
echo "*** Add CrowdStrike Helm repository *************************************************************************************************"

################################################
# ADD CROWDSTRIKE FALCON HELM CHART REPOSITORY #
################################################

helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
helm repo update
helm repo list

echo "*** Step a-04 ***********************************************************************************************************************"
echo "*** JQ Installation *****************************************************************************************************************"

###################
# JQ INSTALLATION #
###################

sudo apt-get install -y jq

echo "*** Step a-05 ***********************************************************************************************************************"
echo "*** Tree installation ***************************************************************************************************************"

#####################
# TREE INSTALLATION #
#####################

sudo apt-get install -y tree

echo "*** Step a-06 ***********************************************************************************************************************"
echo "*** K3S installation ****************************************************************************************************************"

####################
# K3S INSTALLATION #
####################

echo "*** Step a-06-1 *********************************************************************************************************************"
echo "*** K3S deployment ******************************************************************************************************************"

#K3S Deployment
curl -sfL https://get.k3s.io | sh -

echo "*** Step a-06-2 *********************************************************************************************************************"
echo "*** Allow the use of kubectl without sudo *******************************************************************************************"

#Allow the use of kubectl without sudo
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"

echo "*** Step a-06-3 *********************************************************************************************************************"
echo "*** Make the change persistent at reboot ********************************************************************************************"

#Make the change persistent at reboot
echo export KUBECONFIG="/home/$USER/.kube/config" >> ~/.bash_profile

echo "*** Step a-06-4 *********************************************************************************************************************"
echo "*** Enable kubectl autocompletion ***************************************************************************************************"

#Enable kubectl autocompletion
echo 'source <(kubectl completion bash)' >> ~/.bash_profile

echo "*** Step a-06-5 *********************************************************************************************************************"
echo "*** Apply the changes ***************************************************************************************************************"

#Apply the changes
source ~/.bash_profile

echo "*** Step a-06-6 *********************************************************************************************************************"
echo "*** Avoid a warning from Helm related to configuration file permissions *************************************************************"

#Avoid a warning from Helm related to configuration file permissions
chmod 600 ~/.kube/config

echo "*** Step a-07 ***********************************************************************************************************************"
echo "*** Download CrowdStrike pull script ************************************************************************************************"

##############################################################
# DOWNLOAD CROWDSTRIKE SCRIPT TO LIST AND DOWNLOAD RESOURCES #
##############################################################

curl -sSL -o falcon-container-sensor-pull.sh "https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/bash/containers/falcon-container-sensor-pull/falcon-container-sensor-pull.sh"
chmod +x falcon-container-sensor-pull.sh

echo "*** Step a-08 ***********************************************************************************************************************"
echo "*** Change the group ID to allow the use of Docker without SUDO (otherwise exit is needed to reload the session *********************"

########################################################################################
# CHANGE THE GROUP ID TO ALLOW USE OF DOCKER WITHOUT SUDO (otherwise "exit" is needed) #
########################################################################################

newgrp docker

#######
# END #
#######