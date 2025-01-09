#!/bin/bash

printf "\n... ... ... begin [1]\n"

CONTAINER_NAME_JENKINS="jenkins-docker"

# Run the Docker-in-Docker container
#
printf "\n... starting up container '$CONTAINER_NAME_JENKINS'.\n\n"

docker run --name $CONTAINER_NAME_JENKINS --rm --detach \
  --privileged --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind --storage-driver overlay2

printf "\nJenkins DinD '$CONTAINER_NAME_JENKINS' has started.\n\n"
