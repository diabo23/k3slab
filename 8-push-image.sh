echo "
██████╗ ██╗   ██╗███████╗██╗  ██╗    ██╗███╗   ███╗ █████╗  ██████╗ ███████╗
██╔══██╗██║   ██║██╔════╝██║  ██║    ██║████╗ ████║██╔══██╗██╔════╝ ██╔════╝
██████╔╝██║   ██║███████╗███████║    ██║██╔████╔██║███████║██║  ███╗█████╗  
██╔═══╝ ██║   ██║╚════██║██╔══██║    ██║██║╚██╔╝██║██╔══██║██║   ██║██╔══╝  
██║     ╚██████╔╝███████║██║  ██║    ██║██║ ╚═╝ ██║██║  ██║╚██████╔╝███████╗
╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
"

export PUB_IMAGE
export PR_TAG

if test -f variables-private-reg.txt; then
  source variables-private-reg.txt
else
  export PR_REGISTRY
  export PR_PASSWORD
  export PR_REPOSITORY
  read -p "Docker Hub Private Registry/Username: " PR_REGISTRY
  read -p "Docker Hub Token: " PR_PASSWORD
  read -p "Target Repository in the Private Registry: " PR_REPOSITORY
  
cat > variables-private-reg.txt <<EOF
export PR_REGISTRY=$PR_REGISTRY
export PR_PASSWORD=$PR_PASSWORD
export PR_REPOSITORY=$PR_REPOSITORY
EOF
fi

read -p "Tag of the Public Image to Pull: " PUB_IMAGE
read -p "Tag to assign to the Image: " PR_TAG

echo $PR_REGISTRY
echo $PR_PASSWORD
echo $PR_REPOSITORY
echo $PUB_IMAGE
echo $PR_TAG

docker pull $PUB_IMAGE
docker tag $PUB_IMAGE $PR_REGISTRY/$PR_REPOSITORY:$PR_TAG
docker login -u $PR_REGISTRY -p $PR_PASSWORD
docker push $PR_REGISTRY/$PR_REPOSITORY:$PR_TAG
