# Welcome to a 2024->2025 Flutter CI/CD Flow with Docker and Jenkins

Please see the following blog post for a visual overview related to this repository.

- The egg came first, which is why this chicken is lost. (i.e. TBA; @TODO:)


## IMPORTANT NOTES

1. The iOS portion of this flow is configured to be run from a Mac, as it uses the Mac host to build an IPA. Ergo, the entire flow is written from a Mac host perspective.
2. When the repository below is cloned, a global search and replace should be done in all files for:
  - 'macuser' => 'yourmacusername'
  - 'My-App' => 'Your-App-Name'
  - 'my-app' => 'your-app-name'
  - 'MY_APP' => 'YOUR_APP_NAME'
  - 'my_app' => 'your_app_name'
  - 'myapp' => 'yourappname'
  - 'com.mydomain.myapp' => Your app's package name
3. Your app in git should have a branch named 'build_release', which will be the branch used by Jenkins.
4. As with anything taken from the web, it should be a common practice to **go through each and every file within the repository**.
  - This is crucial not only to have an understanding of what you will be running, but in the case anything was missed that may require additional configuration. Missing steps are typically things done during the initialization phase that were forgotten some 300 builds later.
5. If things do not work, examine closely things like permissions (`chmod +x script.sh`), capitalization, and hyphens vs. underscores.
6. For further clarification or trouble spots, please visit the Jenkins documentation provided at the bottom of this readme.


## STEP 1 | PREREQUISITES: Cloning and Folder Structure

### Terminal

```sh
> % cd /Users/macuser/
> % mkdir -p Development/jenkins-workspace/
> % chmod +x Development/jenkins-workspace/
> % mkdir -p Development/projects/src/keys/
> % cd Development/projects/src
> % git clone https://github.com/KDCinfo/flutter-jenkins-docker-ci-cd.git dev-mac
```

**Note:** Adding the 'dev-mac' on the end of the clone will alleviate the need for another global search and replace.

The clone above should create the following structure:

- Development/projects/src/dev-mac/assets
- Development/projects/src/dev-mac/jenkins-docker
- Development/projects/src/dev-mac/jenkins-docker-agent

Placement of secret keys is assumed to be at (as created above):

- Development/projects/src/keys

Placement of Flutter app files is assumed to be at:

- Development/projects/flutter-apps/myapp


## STEP 2 | Setup and Startup

Please see the '[README.md](jenkins-docker-agent/README.md)' in the 'jenkins-docker-agent' folder for ramaining setup instructions.


## Background

As you may have already discovered when researching Flutter CI/CD flows, there are a handful of starter templates on the web for a Jenkins-based CD flow using Docker containers. Those helpful guides and template files are shared by developers like ourselves over the last few years who have wound their way through all the docs, or by other means. For better or worse, from an always-learning dev, this is my monthslong consolidated contribution to the topic.

There are a lot of tedious details in setting all this up. Hopefully these files will help someone else with their own troubles or challenges with a similar setup.

Aside from a couple tutorials, this entire workflow began with the Jenkins documentation, although was complemented, and later supplanted by a couple threaded conversations with ChatGPT:Claude.

- Jenkins: Installing Docker on MacOS and Linux
- https://www.jenkins.io/doc/book/installing/docker/
	Which leads to:
	- https://www.jenkins.io/doc/book/installing/docker/#on-macos-and-linux

_
