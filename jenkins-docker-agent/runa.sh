#!/bin/bash

JENKINS_URL="http://localhost:8080/"
SECRET_FILE="../../keys/secretfile"
AGENT_NAME="mac-host"

java -jar agent.jar \
  -url ${JENKINS_URL} \
  -secret @${SECRET_FILE} \
  -name ${AGENT_NAME} -webSocket \
  -workDir "/Users/macuser/Development/projects/src/dev-mac/jenkins-docker-agent"
