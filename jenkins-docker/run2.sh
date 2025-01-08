#!/bin/bash

printf "\n... ... ... begin [2]\n"

CONTAINER_NAME_BLUEOCEAN="jenkins-blueocean"

# Build the custom Jenkins Docker image from Dockerfile
#
printf "\n... building myjenkins-blueocean (new images can take a few minutes)\n\n"
docker buildx build -f DockerfileController -t myjenkins-blueocean .
printf "\n... ... ... starting Jenkins Controller\n"

# Run or Start the Jenkins container with the custom image
#
printf "\n... starting up container '$CONTAINER_NAME_BLUEOCEAN'.\n\n"

docker run --name $CONTAINER_NAME_BLUEOCEAN --restart=unless-stopped --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean

# CONTAINER_NAME_BLUEOCEAN="jenkins-blueocean"
# docker exec jenkins-blueocean \
#   sudo chmod 660 /var/run/docker.sock \
#   sudo chown root:docker /var/run/docker.sock
# docker exec jenkins-blueocean \
#   groups \
#   groups jenkins \
#   ls -la /var/run/docker.sock

printf "\nJenkins DinD '$CONTAINER_NAME_BLUEOCEAN' has started.\n\n"
