This Terraform workflow updates the Azure DNS zone to publish the API and *.apps A records for the OpenShift Cluster, using the Public IP address provisioned with the Application Gateway.

The Terrform workflow dynamically retrieves the Public IP address and DNS Zone information and creates / updates the records as required.

This workflow can be manually run using the [deploy-public-dns-record.sh](../deploy-public-dns-records.sh) script.