
The following resources are deployed:

| Quantity | Type | Description |
|--------|------|-------------|
|1| Resource Group| logical container for the resources|
|1| Virtual network| SDN network for hosting management resources. Peered with Cluster Vnets (Hub / Spoke)|
|1| Azure Firewall| for internet egress control for the clusters|
|1| Azure Firewall Policy| associated with the Azure Firewall|
|1| Azure Key Vault| store centralized secrets / certificates required by the Azure resources|
|1| Azure DNS Zone|Public DNS Zone. Hosts A records for *.apps and api endpoints for the clusters, using the App GW Public IP address.|
|1| Log Analytic Workspace| Log storage solution for the management resources|
|1| Network Security Group| Network inbound/outbound security solution applied to the management VNet / Subnets|
|1| Azure Bastion| Secure network session manager for IaaS resources|
|2| Public IP addresses| associated to Azure Bastion and Azure Firewall resources|
