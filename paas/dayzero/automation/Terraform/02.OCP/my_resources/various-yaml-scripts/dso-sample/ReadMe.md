# Juice-Shop Pipeline

In this repository is all of the code required to deploy juice-shop into Openshift.

The flow of this is as follows:

`Git-Clone Juice-Shop Repository -> Perform SAST testing using Sonarqube -> Build Juice-Shop from the Dockerfile and push to the Quay repo -> Deploy using ArgoCD -> Perform DAST scanning using Owasp-Zap`

There are some pre-requisites for this however:

+ You must have ArgoCD set up on Openshift with an exposed route
+ You must have a Quay Repository set up
+ You mus have your own namespace set up in OpenShift to work out of
+ You must create a robot account on Quay which has write access to the repository you want to push to - Replace the value in the Authentication/secrets.yaml file with this service account key
+ Similarly to the step above, you must also replace github token with a token that has access to the GitHub repo you will be cloning from. 
+ You must have a Manifests file (like in this repo) that ArgoCD is actively monitoring for any changes
+ You have a SonarQube instance set up and running. This can be done by following the guide [here](https://github.com/defencedigital/dso-pipeline-tooling/tree/master/Sonarqube).
+ You must have a sonar-properties file in the GitHub repository. An example for Juice-shop can be found [here](https://github.com/defencedigital/dso-pipeline-integration/blob/master/juice-shop/examples/sonar-properties.properties). 
+ Ensure KeyVault is setup with a project, and ensure this project has access to the secret. Documentation on how to do this is found [here](https://github.com/defencedigital/dso-scm/blob/main/Onboarding-Docs/VaultOnboarding.md#configuring-kubernetes-access-to-a-single-secret-admin)


After that, run a `kubectl apply -f <file>` with all of the tasks, secrets and pipeline files. It should then all be working.

Be sure to replace the values in the PipelineRun with the values you require.


## Setting up the Juice-Shop pipeline from scratch

This section details how to run the juice-shop pipeline from scratch.

### Glone the GitHub repo

First of all, clone this repo and `cd` into this folder

```
git clone https://github.com/defencedigital/dso-pipeline-integration.git
cd dso-pipeline-integration/juice-shop
```
### Install the Tasks

Next the tasks will need to be created in OpenShift. Run the following commands:

```
oc apply -f Misc/sonar-source-pvc.yaml,Tasks/sonarqube-scanner.yaml,../../common/ClusterTask/vault-build-image.yaml,../../common/ClusterTask/git-update-deployment.yaml,Tasks/Owasp-Zap-Task.yaml -n <namespace>
```

Where -n specifies the namespace you want to install the tasks in.

The tasks involved do the following:

+ sonar-source-pvc - installs the persistent volume claime used by the SonarQube Scanner
+ sonarqube-scanner - creates the task that will run SonarQube against the application
+ build-service-task - This will build the image from the Dockerfile, and push it up to the Quay repository
+ git-update-deployment - This will update the Manifests file in the GitHub repo with the new version being pushed. ArgoCD monitors this file, and when it is changed, it kicks off a new deployment.
+ Owasp-Zap-Task - This Task will run an Owasp Zap scan against the application

### Install the Pipeline

Next the pipeline and Pipeline Run file will need to be installed.

In this instance, there are two pipelines. One for pre-deployment and one for post-deployment. The reason for this is due to the timings of how long it takes to deploy the application. Owasp Zap is a tool that scans the application after deployment. If it was to be included in the first pipeline all in one stage, then it could potentially begin running before ArgoCD has finished deploying the application, thus not running against the new deployment.

NOTE: This will start the pipelines, however they are not intended to succeed as it is just an out of the box install. Despite two pipelines being installed here, once the full installation is complete, you will not need to manually kick off the second. It will be done automatically due to the GitHub triggers.

```
oc apply -f Pipeline/pipeline-pd.yaml,Pipeline/pipeline.yaml -n <namespace>
oc create -f Pipeline/PipelineRun-pd.yaml,Pipeline/PipelineRun.yaml -n <namespace>
```

### GitHub triggers

The GitHub triggers will then need to be installed. The purpose of these triggers is to start the pipeline in OpenShift and to kick off the post deployment pipeline.

To add the triggers, run: 
```
oc apply -f Misc/triggers/github/,Misc/triggers/post-deployment/ -n <namespace>
```

Next we need to add the webhook into the GitHub code repository. Navigate to where the code repository is stored and follow the following steps:

Click on Settings:

<img width="1572" alt="Screenshot 2022-01-14 at 11 32 57" src="https://user-images.githubusercontent.com/90788425/149509729-20d71c4a-fcf2-4340-bca4-b4fe8e283029.png">

Select Webhooks:

<img width="1260" alt="Screenshot 2022-01-14 at 11 33 02" src="https://user-images.githubusercontent.com/90788425/149509752-a746a320-182f-4070-86ba-f154ad5b1e24.png">

Select "Add a Webhook":

<img width="815" alt="Screenshot 2022-01-14 at 11 33 08" src="https://user-images.githubusercontent.com/90788425/149509780-e3421faa-3621-4997-b081-9aa7a4759698.png">


In the URL field, this value can be taken from the _Misc/triggers/github/05_expose_service.yaml_ file on line 28, as shown below.

<img width="1249" alt="Screenshot 2022-01-14 at 11 33 57" src="https://user-images.githubusercontent.com/90788425/149509938-44f30e4d-d7d8-4a83-8ea7-5047edc9e2cf.png">

**Remember to put "https://" before the URL**

For content type select "application/json"

For SSL Verification select "Disable"

For which events would you like to trigger this webhook, leave it as "Just the push event"

<img width="797" alt="Screenshot 2022-01-14 at 11 34 31" src="https://user-images.githubusercontent.com/90788425/149510225-31002317-af79-40dd-9e80-3f13acfdb11c.png">



### Authentication

<Bilal to complete>
  
  
### Kicking off the pipeline

Once everything is configured, configure your parameters to be used in the PipelineRun files mentioned earlier. Then run a `kubectl apply -f <PipelineRun> -n <namespace>` to save the changes in OpenSift

Now that everything is ready, in order to start the pipeline all you need to do is change the version number in Manifests/Kustomization.yaml on line 13 as shown below:

<img width="1255" alt="Screenshot 2022-01-14 at 11 28 16" src="https://user-images.githubusercontent.com/90788425/149508349-e6d44226-f46f-43ac-a774-2f28ebfc490b.png">

This should then kick off the pipeline in OpenShift. If all is working correctly, then you should see a pipeline running in the Openshift interface.
