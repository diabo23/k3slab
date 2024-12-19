echo "
 ██████╗███████╗    ██╗   ██╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██╗     ███████╗███████╗
██╔════╝██╔════╝    ██║   ██║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
██║     ███████╗    ██║   ██║███████║██████╔╝██║███████║██████╔╝██║     █████╗  ███████╗
██║     ╚════██║    ╚██╗ ██╔╝██╔══██║██╔══██╗██║██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
╚██████╗███████║     ╚████╔╝ ██║  ██║██║  ██║██║██║  ██║██████╔╝███████╗███████╗███████║
 ╚═════╝╚══════╝      ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝
"

#The script needs 4 parameters given to it
# - The parameters could be given to it in an interactive way; this happens if you run the script with no parameters and you'll have to provide it one by one.
# - As an alternative, you can run the parameters giving the first three parameters (CID, CrowdStrike Cloud Region and API Client ID) separated by a blank space; in this case the script will just ask you for the API Client Secret
#Given the sensitivity of the API Client Secret, while you enter it or while you paste it, the text won't appear in the terminal; once provided, just press Enter to pass it to the script.

export FALCON_CID
export CROWDSTRIKE_CLOUD_ENV
export FALCON_CLIENT_ID
export FALCON_CLIENT_SECRET

if [ $# -eq 3 ]
        then
                FALCON_CID=$1
                CROWDSTRIKE_CLOUD_ENV=$2
                FALCON_CLIENT_ID=$3
                read -s -p "CrowdStrike API Client Secret: " FALCON_CLIENT_SECRET
        else
                read -p "CrowdStrike CID: " FALCON_CID
                read -p "CrowdStrike Cloud Region: " CROWDSTRIKE_CLOUD_ENV
                read -p "CrowdStrike API Client Key: " FALCON_CLIENT_ID
                read -s -p "CrowdStrike API Client Secret: " FALCON_CLIENT_SECRET
fi

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