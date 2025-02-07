export PUB_IMAGE
export PR_REGISTRY
export PR_PASSWORD
export PR_REPOSITORY
export PR_TAG

read -p "Tag of the Public Image to Pull (e.g. hello-world:linux): " PUB_IMAGE
read -p "Docker Hub Private Registry/Username: " PR_REGISTRY
read -p "Docker Hub Token: " PR_PASSWORD
read -p "Target Repository in the Private Registry: " PR_REPOSITORY
read -p "Tag to assign to the Image (e.g. hello-world-1): " PR_TAG

docker pull $PUB_IMAGE
docker tag $PUB_IMAGE $PR_REGISTRY/$PR_REPOSITORY:$PR_TAG
docker login -u $PR_REGISTRY -p $PR_PASSWORD
docker push $PR_REGISTRY/$PR_REPOSITORY:$PR_TAG
