# Jenkins Pipelines, Nodes, and Credentials

The following are all the properties and values for creating two pipelines, one node, and credentials.


## Pipelines

Two Jenkins Pipelines will need to be created.

### my-app-deploy

- Discard old builds
  - Log Rotation: Max #: 30
- Do not allow concurrent builds
- Do not allow the pipeline to resume if the controller restarts
- Pipeline: Pipeline script from SCM
  - Git:
    - url: https://github.com/macuser/myapp/
    - credentials: macuser/****** (`jenkinsmacdockertoken`)
  - Branches to build
    - > */build_release
    - @TODO: Ensure to create a branch named `build_release` in your repository.
- Script Path
  - > app/Jenkinsfile
  - Given your git checkout is the parent of `app/`.

### my-app-deploy-ios

- Discard old builds
  - Log Rotation: Max #: 30
- Do not allow concurrent builds
- Do not allow the pipeline to resume if the controller restarts
- This project is parameterized
  - String Parameter:
    - Name: APP_BUILD_NUMBER
    - Default Value: 0
    - Desc: Build Number of Parent Pipeline
  - String Parameter:
    - Name: MMP_VERSION
    - Default Value: 0.0.0
    - Desc: Major.Minor.Patch Version
  - String Parameter:
    - Name: NEW_VERSION
    - Default Value: 0.0.0+0
    - Desc: Major.Minor.Patch+Build Version
- Pipeline: Pipeline script from SCM
  - Git:
    - url: https://github.com/macuser/myapp/
    - credentials: macuser/****** (`jenkinsmacdockertoken`)
  - Branches to build
    - > */build_release
    - @TODO: Double check that you have a branch named `build_release` in your repository.
- Script Path
  - > app/Jenkinsfile_iOS
  - Given your git checkout is the parent of `app/`.


## Nodes

1. `Built-In Node` | I did nothing with this.
2. `flutter-node` | Linux (amd64)
  - Number of executors: 1
  - Remote root dir: /home/developer
  - Labels: flutter
  - Usage: Only build jobs with label expressions matching this node
  - Launch method: Launch agent by connecting it to the controller
  - Availability: Bring this agent online when in demand, and take offline when idle
    - In demand delay: 0
    - Idle delay: 5
3. `mac-host` | We'll create the 3rd (final) agent node back in the 'jenkins-docker-agent/README.md' file.


## Credentials

You will need to check into getting keys if you don't already have them, particularly for the 'Google Play JSON Token' and 'App Store Connect API Key'. Hopefully my notes will help fill in the pieces.

```
User w pass | jenkinsmacdockertoken | macuser/****** (jenkinsmacdockertoken) - Got when installing Jenkins (IIRC)

Secret FILE | ANDROID_KEYSTORE | key.jks (Signing key file for Android)
Secret text | ANDROID_STORE_PASSWORD | Android Deployment
Secret text | ANDROID_KEY_PASSWORD | Android password for key
Secret FILE | GOOGLE_PLAY_JSON_TOKEN_MY_APP | gcloud-my-app-16---9c.json (Json token for fastlane deployment to Play Store.)

Secret text | APPLE_APPLICATION_CREDENTIALS | Email: my@email.com
Secret text | APPLE_APPLICATION_ID | App Store Connect Team ID
Secret FILE | APP_STORE_CONNECT_API_KEY | AuthKey_00000XX0XX.p8 (App Store Connect API Key)
Secret text | KEYCHAIN_PASSWORD | Local Mac
Secret text | APP_STORE_CONNECT_ISSUER_ID | Issuer ID: 75a...-c708-...-...-...5b3 (from app store connect > Users > Integrations -> Team Keys)
```


_
