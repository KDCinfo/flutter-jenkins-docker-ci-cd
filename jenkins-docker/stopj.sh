#!/bin/bash

CONTAINER_NAME_JENKINS="jenkins-docker"
CONTAINER_NAME_BLUEOCEAN="jenkins-blueocean"
CONTAINER_NAME_FLUTTER="flutter-node"

# Stop Jenkins containers in the correct order
if docker ps --filter "name=$CONTAINER_NAME_FLUTTER" | grep -q "$CONTAINER_NAME_FLUTTER"; then
  docker stop $CONTAINER_NAME_FLUTTER
fi

if docker ps --filter "name=$CONTAINER_NAME_BLUEOCEAN" | grep -q "$CONTAINER_NAME_BLUEOCEAN"; then
  docker stop $CONTAINER_NAME_BLUEOCEAN
fi

if docker ps --filter "name=$CONTAINER_NAME_JENKINS" | grep -q "$CONTAINER_NAME_JENKINS"; then
  docker stop $CONTAINER_NAME_JENKINS
fi

echo "Jenkins containers have been stopped."
