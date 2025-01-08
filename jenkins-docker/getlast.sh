#!/bin/bash

# # Replace with your Jenkins URL and job name
# JENKINS_URL="http://localhost:8080/job/my-app-deploy"

# # Get the last build number from the Jenkins API
# last_build_number=$(curl -s "${JENKINS_URL}/api/json" | grep -Eo '"number":([0-9]+)')

# # Extract just the build number
# last_build_number=${last_build_number#*:}
# echo "Last build number: $last_build_number"

# # Proceed with your build logic using the retrieved build number

# -----

# # Get the last build number from the Jenkins API
# JENKINS_URL="http://localhost:8080/job/my-app-deploy"
# last_build_number=$(curl -s "${JENKINS_URL}/api/json" | jq '.lastCompletedBuild.number')
# echo "Last build number: $last_build_number"
# # Use the 'last_build_number' as needed in your build process

# -----

# Define variables
JENKINS_URL="http://localhost:8080"
JOB_NAME="my-app-deploy"

TOKEN_FILE="../../keys/secretjenkinsapikey"
read -r token < "${TOKEN_FILE}"
API_TOKEN="$token"
API_USER="auser"

# Query the Jenkins API to get the last build number
LAST_BUILD_NUMBER=$(curl -s -u "$API_USER:$API_TOKEN" "$JENKINS_URL/job/$JOB_NAME/lastBuild/buildNumber")

echo "Last Build Number: $LAST_BUILD_NUMBER"
