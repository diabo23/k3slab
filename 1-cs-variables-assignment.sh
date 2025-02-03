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
# - As an alternative, you can run the parameters giving the first three parameters (CID, CrowdStrike Cloud Region, API Client ID, API Client Secret) separated by a blank space.

export FALCON_CID
export CROWDSTRIKE_CLOUD_ENV
export FALCON_CLIENT_ID
export FALCON_CLIENT_SECRET

if [ $# -eq 4 ]
        then
                FALCON_CID=$1
                CROWDSTRIKE_CLOUD_ENV=$2
                FALCON_CLIENT_ID=$3
                FALCON_CLIENT_SECRET=$4
        else
                read -p "CrowdStrike CID: " FALCON_CID
                read -p "CrowdStrike Cloud Region (lower case: us-1, us-2, eu-1, us-gov-1, us-gov-2): " CROWDSTRIKE_CLOUD_ENV
                read -p "CrowdStrike API Client Key: " FALCON_CLIENT_ID
                read -p "CrowdStrike API Client Secret: " FALCON_CLIENT_SECRET
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

#Write these variables in a text file so we can use it for quick reassignment (via "source variables.txt")
cat > variables.txt <<EOF
export FALCON_CID=$FALCON_CID
export CROWDSTRIKE_CLOUD_ENV=$CROWDSTRIKE_CLOUD_ENV
export FALCON_CLIENT_ID=$FALCON_CLIENT_ID
export FALCON_CLIENT_SECRET=$FALCON_CLIENT_SECRET
export FALCON_IMAGE_PULL_TOKEN=$FALCON_IMAGE_PULL_TOKEN
EOF