export PR_REGISTRY
export PR_PASSWORD
export PR_REPOSITORY
export PR_TAG

read -p "Docker Hub Private Registry/Username: " PR_REGISTRY
read -p "Docker Hub Token: " PR_PASSWORD
read -p "Target Repository in the Private Registry: " PR_REPOSITORY
read -p "Tag to assign to the Image: " PR_TAG

docker tag wordpress:beta-php8.3-fpm-alpine $PR_REGISTRY/$PR_REPOSITORY:$PR_TAG
docker login -u $PR_REGISTRY -p $PR_PASSWORD
docker push $PR_REGISTRY/$PR_REPOSITORY:$PR_TAG
