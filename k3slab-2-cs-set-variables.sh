echo "
 ██████╗███████╗    ██╗   ██╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██╗     ███████╗███████╗
██╔════╝██╔════╝    ██║   ██║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
██║     ███████╗    ██║   ██║███████║██████╔╝██║███████║██████╔╝██║     █████╗  ███████╗
██║     ╚════██║    ╚██╗ ██╔╝██╔══██║██╔══██╗██║██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
╚██████╗███████║     ╚████╔╝ ██║  ██║██║  ██║██║██║  ██║██████╔╝███████╗███████╗███████║
 ╚═════╝╚══════╝      ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝
"

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

export FALCON_ART_USERNAME=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --dump-credentials \
  | grep "CS Registry Username" | awk -F ": " '{print $2}')

export FALCON_ART_PASSWORD=$(./falcon-container-sensor-pull.sh \
  -u $FALCON_CLIENT_ID \
  -s $FALCON_CLIENT_SECRET \
  --dump-credentials \
  | grep "CS Registry Password" | awk -F ": " '{print $2}')

export PARTIALPULLTOKEN=$(echo -n "$FALCON_ART_USERNAME:$FALCON_ART_PASSWORD" | base64 -w 0)
export FALCON_IMAGE_PULL_TOKEN=$(echo "{\"auths\":{\"registry.crowdstrike.com\":{\"auth\":\"$PARTIALPULLTOKEN\"}}}" | base64 -w 0)

#source ~/.bash_profile

echo ""