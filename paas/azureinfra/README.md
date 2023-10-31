# Azure Infra for Private Red Hat OpenShift clusters

This repository contains the code required to deploy the supporting Azuer infrastructure to host Red Hat OpenShift private clusters, deployed by the Installer Provisioned Infrastructure (IPI) method.

https://docs.openshift.com/container-platform/4.9/installing/installing_azure/installing-azure-private.html

Terraform is used to deploy the Azure resources.

The TF State files are stored in an Azure Storage Account contaner. Prior to running any Terraform workflows, this Storage Account needs to be deployed. This [script](./mgmt/deploy-tf-state.sh) can be run from a Linux system / Azure CloudShell Bash session to create the resource group and storage account. This only needs to be run once.

## Management

The central management resources are deployed to a separate Azure Subscription. It is intended that  there is a single management subscription within an organization, enabling centralised management and monitoring of the OpenShift clusters.

The code to deploy the resources is located in the [mgmt](./mgmt) folder.

The workflow creates a Resource Group, Virtual Network with various subnets, a network security group, Log Analytics Workspace, Azure Firewall for controlling internet egress from the connected networks and an Azure Bastion, for secure session management to IaaS resources.

## OCP Cluster Management

For each private OpenShift cluster that is deployed within Azure, there is independent infrastructure management resources deployed, dedicated to the cluster.

The resources are intended to be deployed to a different subscription to which is hosting the centralized management resources, but can be simply adapted to deploy to the same subscription.

The code to deploy the resources is located in the [ocpCLuster](./ocpCLuster) folder.

The workflow creates a Resource Group, Virtual Network with various subnets, a network security group, Log Analytics Workspace and a RHEL 8 Linux VM, which is used for cluster provisioning and break glass operations.

The IaaS VM provisioning automates the installation of the tools required to perform the IPI install, OpenShift CLI, Azure CLI and the installation config file, ready to deploy a cluster instance.

## Application Gateway (WAF)

A separate workflow is provided if there is a requirement to publish applications and services securely to the public. The code deploys an Application Gateway (WAF) to the OCP Managemnt resource group.  It also deploys a WAF Policy which is associated to the APplication Gateway Resource, applying the OWASP 3.2 top ten ruleset, as well as the Microsoft Botnet ruleset. The ability to allow known IPs to the App GW is provided, so that testing and commissioning can be performed as securely as possible, prior to production sign-off.

The code to deploy the resources is located in the [app-gw](./app-gw) folder.

When the Application Gateway is first created, some default ingress rules are created for the cluster instance. As HTTPS is used, a self-signed certificate is generated and stored in the Key Vault located in the Management subscription. THis is intended only for the initial installation. A separate process updates the listener certificate using a Trusted CA chain (Zero SSL). [**Link here to the process when written**](./README.md)


## Azure Firewall

All egress traffic outside of the environment is routed via an Azure Firewall located in the management subscription.  This offers traffic filtereing and centralised logging.

As the lifecycle of the Azure Firewall rules is likely to have a faster cadence, updating of the policies is run as a separate workflow. The folder [az-firewall-policy](./ az-firewall-policy) hosts the workflow.

## Installation 

Read the [Installation documentation](./docs/installation.md) on the installation order for the environment.