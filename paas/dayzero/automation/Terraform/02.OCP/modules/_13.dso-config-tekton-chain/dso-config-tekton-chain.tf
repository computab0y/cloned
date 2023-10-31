
terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"  # for offline plugin setup
      version = ">= 1.14.0"
    }
  }
}

provider "kubectl" {
  host                   = "${var.host}"    
  token                  = "${var.token}"  
  load_config_file       = false
  insecure = "${var.tls-insecure}"  
}

# ********  create verify-deploy-namespace
resource "kubectl_manifest" "create-verify-deploy-namespace" {
    yaml_body = <<YAML

apiVersion: v1
kind: Namespace
metadata:
  name: ${var.verify-deploy-namespace}
  annotations:
    openshift.io/display-name: '${var.verify-deploy-namespace}'

YAML
}

# ********  create task-cluster-cosign-verify
resource "kubectl_manifest" "create-task-cluster-cosign-verify" {
    yaml_body = <<YAML

apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: cosign-verify
  namespace: ${var.verify-deploy-namespace}
spec:
  description: These tasks make it possible to use cosign within your Tekton pipelines to verify signed images
  params:
    - name: ToolBoxUrl
      type: string
    - name: quayUrl
      type: string
    - name: quayUser
      type: string
    - name: quayToken
      type: string
    - name: repoPath
      type: string
    - name: imageTag
      type: string
  steps:
  - image: '$(params.ToolBoxUrl)'
    name: cosign-verify
    resources: {}
    env:
      - name: QUAY_URL
        value: $(params.quayUrl)
      - name: REPO_PATH
        value: $(params.repoPath)
      - name: IMAGE_TAG
        value: $(params.imageTag)
      - name: QUAY_USER
        value: $(params.quayUser)
      - name: QUAY_TOKEN
        value: $(params.quayToken)
      - name: COSIGN_PUB
        valueFrom:
          secretKeyRef:
            name: signing-secrets
            key: cosign.pub
    script: >
      #!/bin/bash

      echo "Verifying... $QUAY_URL/$REPO_PATH:$IMAGE_TAG"

      echo "$COSIGN_PUB" > cosign.pub
      
      CMD1="cosign login -u $QUAY_USER -p $QUAY_TOKEN $QUAY_URL"
      
      CMD2="cosign verify --key cosign.pub $QUAY_URL/$REPO_PATH:$IMAGE_TAG"

      echo $CMD1

      $${CMD1} &> cmd1-result

      cat cmd1-result

      echo $CMD2

      $${CMD2} &> cmd2-result

      cat cmd2-result

      err=$?

      ERR_MSG="Failed to verify image"

      if [[ $${err} -ne 0 ]]; then

        echo "$${ERR_MSG}"
        exit 1
      fi

YAML
}

# ********  create task-cluster-skopeo-copy-single
resource "kubectl_manifest" "create-task-cluster-skopeo-copy-single" {
    yaml_body = <<YAML

apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: skopeo-copy-single
  namespace: ${var.verify-deploy-namespace}
spec:
  description: |-
    Skopeo is a command line tool for working with remote image registries.
    Skopeo doesn’t require a daemon to be running while performing its operations. 
    In particular, the handy skopeo command called copy will ease the whole image copy operation. 
    The copy command will take care of copying the image from internal.registry to production.registry. 
    If your production registry requires credentials to login in order to push the image, skopeo can handle that as well.
  params:
  - default: ""
    description: URL of the Toolbox Image
    name: ToolBoxUrl
    type: string
  - default: ""
    description: URL of the source image 
    name: srcImageURL
    type: string
  - default: ""
    description: URL of the destination image
    name: destImageURL
    type: string
  - default: ""
    description: Credentials of the source registry
    name: srcCreds
    type: string
  - default: ""
    description: Credentials of the destination registry
    name: destCreds
    type: string
  - default: "true"
    description: Verify the TLS on the src registry endpoint
    name: srcTLSverify
    type: string
  - default: "true"
    description: Verify the TLS on the dest registry endpoint
    name: destTLSverify
    type: string
  steps:
  - image: $(params.ToolBoxUrl)
    name: skopeo-copy
    resources: {}
    script: |
      #! /bin/bash
      CMD="skopeo copy docker://$(params.srcImageURL) docker://$(params.destImageURL) --src-creds $(params.srcCreds) --dest-creds $(params.destCreds) --src-tls-verify=$(params.srcTLSverify) --dest-tls-verify=$(params.destTLSverify)"

      $${CMD} &> result
      cat result

YAML
}

# ********  create public key secret
resource "kubectl_manifest" "create-verify-deploy-secret" {
    yaml_body = <<YAML

kind: Secret
apiVersion: v1
metadata:
  name: signing-secrets
  namespace: ${var.verify-deploy-namespace}
data:
  cosign.pub: ${var.verify-deploy-public-key}
type: Opaque

YAML
}

# ********  create verify pipeline
resource "kubectl_manifest" "create-verify-pipeline" {
    yaml_body = <<YAML

apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: verify-image-pl
  namespace: ${var.verify-deploy-namespace}
spec:
  params:
    - description: URL of the Toolbox image
      name: ToolBoxUrl
      type: string
    - description: URL of the source image (Signature Image in Dev Quay)
      name: srcImageURL
      type: string
    - description: URL of the destination image (Signature Image in Prod Quay)
      name: destImageURL
      type: string
    - description: Credentials of the source registry
      name: srcCreds
      type: string
    - description: Credentials of the destination registry
      name: destCreds
      type: string
    - default: 'true'
      description: Verify the TLS on the src registry endpoint
      name: srcTLSverify
      type: string
    - default: 'true'
      description: Verify the TLS on the dest registry endpoint
      name: destTLSverify
      type: string
    - description: Quay URL (Where the image that will be verified)
      name: quayUrl
      type: string
    - description: Robot Account username
      name: quayUser
      type: string
    - description: Robot Account token
      name: quayToken
      type: string
    - description: Path for image to be verified
      name: repoPath
      type: string
    - description: Image Tag
      name: imageTag
      type: string
  tasks:
    - name: copy-signature-image
      params:
        - name: ToolBoxUrl
          value: $(params.ToolBoxUrl)
        - name: srcImageURL
          value: $(params.srcImageURL)
        - name: destImageURL
          value: $(params.destImageURL)
        - name: srcCreds
          value: $(params.srcCreds)
        - name: destCreds
          value: $(params.destCreds)
        - name: srcTLSverify
          value: $(params.srcTLSverify)
        - name: destTLSverify
          value: $(params.destTLSverify)
      taskRef:
        kind: ClusterTask
        name: skopeo-copy-single
    - name: verify-image
      params:
        - name: ToolBoxUrl
          value: $(params.ToolBoxUrl)
        - name: quayUrl
          value: $(params.quayUrl)
        - name: quayUser
          value: $(params.quayUser)
        - name: quayToken
          value: $(params.quayToken)
        - name: repoPath
          value: $(params.repoPath)
        - name: imageTag
          value: $(params.imageTag)
      taskRef:
        kind: ClusterTask
        name: cosign-verify
      runAfter:
      - copy-signature-image

YAML
}



