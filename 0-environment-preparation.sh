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

#Fetches the latest version of the package list
sudo apt-get update

#Uninstall all Docker conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg -y; done

# Add Docker's official GPG key:
sudo apt-get update
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

#Install Helm
sudo snap install helm --classic

#Add CrowdStrike Falcon Helm Chart Repository
helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
helm repo update
helm repo list

#Install JQ
sudo apt install -y jq

#Install K3s
curl -sfL https://get.k3s.io | sh -

#Allow the use of kubectl without sudo
export KUBECONFIG=~/.kube/config
mkdir ~/.kube 2> /dev/null
sudo k3s kubectl config view --raw > "$KUBECONFIG"

#Make the change persistent at reboot
echo export KUBECONFIG="/home/$USER/.kube/config" >> ~/.bash_profile

#Enable Auto-Completion for Kubectl
echo 'source <(kubectl completion bash)' >>~/.bash_profile

#Enable the changes in the current shell (not valid after the "newgrp docker" command at the end)
source ~/.bash_profile

#Avoid the “Kubernetes configuration file is group-readable. This is insecure.” error when installing Helm Chart
chmod 600 ~/.kube/config

#Set the hostname
sudo hostnamectl set-hostname ubuntu-box

#Set the FQDN
sudo bash -c 'echo "127.0.0.1 ubuntu-box.k3s.lab ubuntu-box" >>/etc/hosts'

#Set the SERVER_FQDN variable
export SERVER_FQDN=$(hostname -f)

#Download the CrowdStrike's script to download the different components of CrowdStrike CNAPP and make it executable
curl -sSL -o ~/falcon-container-sensor-pull.sh "https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/bash/containers/falcon-container-sensor-pull/falcon-container-sensor-pull.sh"
chmod +x ~/falcon-container-sensor-pull.sh

#Change the Group ID to immediately activate the use of Docker without sudo (otherwise exit or reboot would be required)
#newgrp docker