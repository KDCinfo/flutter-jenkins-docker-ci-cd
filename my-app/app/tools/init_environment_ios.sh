#!/bin/bash

set -e

flutter config --no-analytics

# Set HOME explicitly if not set
# export HOME=${HOME:-/home/developer}

#
# FOR DEBUGGING
#

# whoami
# echo "whoami: $(whoami)"

# echo "All users:"
# awk -F: '{ print $1}' /etc/passwd | sort | uniq

# echo "Cat /etc/passwd:"
# cat /etc/passwd | awk -F: '{print $1}'

# workspace
# echo "Developer:"
# ls -ld /home/developer
# ls -la /home/developer

# echo "Workspace:"
# ls -ld /home/developer/workspace
# ls -la /home/developer/workspace

# echo "printenv: "
# printenv

#
# INITIALIZE / RESET FLUTTER
#

echo "### Ensuring the environment is clean and ready to use..."
flutter doctor
flutter clean

echo "### Getting packages for app and local packages..."
flutter pub get

echo "### Running Flutter precache for iOS..."
flutter precache --ios

echo "### Environment Setup Complete"
