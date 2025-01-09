# My-App

From [jenkins-docker-agent/README.md] | Part 5

- Step 1: Set up fastlane

```sh
# pwd  # /my-app
cd app/

# Set up Android
cd android
fastlane init
cd fastlane
# Replace 'Appfile' and 'Fastfile'
cp -R ../fastlane_cd/* .

# Set up iOS
cd ../../ios
fastlane init
cd fastlane
cp -R ../fastlane_cd/* .
```

- Step 2: Replace this entire file with your own app's readme.

- Step 3: Return to [jenkins-docker-agent/README.md] | Part 6
