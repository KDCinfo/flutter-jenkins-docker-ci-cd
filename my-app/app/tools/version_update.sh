#!/bin/bash

set -e

PUBSPEC_FILE=$1
PUBSPEC_MMP_VERSION_WITH_JENKINS_BUILD_NUMBER=$2

# Ensure variables are defined
if [[ -z "${PUBSPEC_MMP_VERSION_WITH_JENKINS_BUILD_NUMBER}" ]]; then
    echo "Error: PUBSPEC_MMP_VERSION_WITH_JENKINS_BUILD_NUMBER is not set."
    exit 1
fi

if [[ ! -f "${PUBSPEC_FILE}" ]]; then
    echo "Error: File not found: ${PUBSPEC_FILE}"
    exit 1
fi

# Update pubspec.yaml with Jenkins build number.
#
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD sed) | Local environment
    sed -i '' "s/^version: .*/version: $PUBSPEC_MMP_VERSION_WITH_JENKINS_BUILD_NUMBER/" "$PUBSPEC_FILE"
else
    # Linux (GNU sed) | Jenkins Docker environment
    sed -i "s/^version: .*/version: $PUBSPEC_MMP_VERSION_WITH_JENKINS_BUILD_NUMBER/" "$PUBSPEC_FILE"
fi
head ${PUBSPEC_FILE}

echo "### Updated [${PUBSPEC_FILE}] with version: ${PUBSPEC_MMP_VERSION_WITH_JENKINS_BUILD_NUMBER}"
