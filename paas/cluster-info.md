# DSO platform cluster information

## Environment information
|Cluster Name|env_instance|Service Offering|Environment|AAD Tenant|Description| Console|
|:-----------|:-|:---------------|:----------|:---------|:----------|:----------|
|[**ocp1**](./azureinfra/SO1/env/env_variables_ocp1.sh)|1|SO1 |Prod |iace |MVP Dev/test (Official Dev) | https://console-openshift-console.apps.ocp1.azure.dso.digital.mod.uk/ |
|[**ocp2**](./azureinfra/SO2/env/env_variables_ocp2.sh)|2|SO2 |Prod |iace |Production Cluster (Official Prod) |  https://console-openshift-console.apps.ocp2.azure.dso.digital.mod.uk/ |
|[**ocp3**](./azureinfra/SO1/env/env_variables_ocp3.sh)|3|SO1 |Sandbox |dev.iace |Sandbox Dev/test (Official Dev Sandbox) | https://console-openshift-console.apps.ocp3.azure.dso.digital.mod.uk/ |
|[**ocp4**](./azureinfra/SO2/env/env_variables_ocp4.sh)|4|SO2 |Sandbox |dev.iace |Sandbox Dev/test (Official Prod Sandbox) | https://console-openshift-console.apps.ocp4.azure.dso.digital.mod.uk/ |

*SO1 : Baseline Service Offering*
*SO2 : Enhanced Service Offering*

## Azure resorce information
|Cluster Name|Infra Subscription|Management Subscription|Key Vault|Log Analytics|default User|Notes|
|:-----------|:-|:-|:---------------|:----------|:---------|:----------|
|[**ocp1**](./azureinfra/SO1/env/env_variables_ocp1.sh)|[UKSC-DD-ASDT_PREDA-INFRA_PROD_001](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/277a8063-d11e-4f34-acf7-b879dfe632eb/overview)|[UKSC-DD-ASDT_PREDA-MGMT_PROD_001](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/233d13b4-dd1d-4d9a-926d-73332a697e07/overview) | [kv-prod-shared-aa-uks](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/233d13b4-dd1d-4d9a-926d-73332a697e07/resourceGroups/rg-mgmt-prod-shared-uks/providers/Microsoft.KeyVault/vaults/kv-prod-shared-aa-uks/overview) |[law-mgmt-prod-shared-uks](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/233d13b4-dd1d-4d9a-926d-73332a697e07/resourceGroups/rg-mgmt-prod-shared-uks/providers/Microsoft.OperationalInsights/workspaces/law-mgmt-prod-shared-uks/Overview) |adminuser|KV/LAW located in MGMT sub | 
|[**ocp2**](./azureinfra/SO2/env/env_variables_ocp2.sh)|[UKSC-DD-ASDT_PREDA-INFRA_PROD_002](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/9f2c9b44-c818-41d7-bd67-938dafd179b5/overview) |***Not Used***|[kv-prod-infra-1288-uks](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/9f2c9b44-c818-41d7-bd67-938dafd179b5/resourceGroups/rg-mgmt-prod-infra-uks/providers/Microsoft.KeyVault/vaults/kv-prod-infra-1288-uks/overview) |[asdt-loganalytics-shpopekuh6](https://portal.azure.com/#@iace.mod.gov.uk/resource/subscriptions/9f2c9b44-c818-41d7-bd67-938dafd179b5/resourceGroups/asdt-audit/providers/Microsoft.OperationalInsights/workspaces/asdt-loganalytics-shpopekuh6/Overview) |sysadmin|KV/LAW located in INFRA sub | 
|[**ocp3**](./azureinfra/SO1/env/env_variables_ocp3.sh)|[UKSC-DD-ASDT_PREDA-INFRA_SBOX_001](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/6f03b888-9d8c-4975-bda3-6cbfbc8f4359/overview)|[UKSC-DD-ASDT_PREDA-MGMT_SBOX_001](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/f87511ec-8d90-43f0-8c16-14212fc2ee16/overview)|[kv-sbox-shared-e1-uks](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/f87511ec-8d90-43f0-8c16-14212fc2ee16/resourceGroups/rg-mgmt-sbox-shared-uks/providers/Microsoft.KeyVault/vaults/kv-sbox-shared-e1-uks/overview) |[law-mgmt-sbox-shared-uks](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/f87511ec-8d90-43f0-8c16-14212fc2ee16/resourceGroups/rg-mgmt-sbox-shared-uks/providers/Microsoft.OperationalInsights/workspaces/law-mgmt-sbox-shared-uks/Overview) |adminuser|KV/LAW located in MGMT sub | 
|[**ocp4**](./azureinfra/SO2/env/env_variables_ocp4.sh)|[UKSC-DD-ASDT_PREDA-INFRA_SBOX_002](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/1a1077b6-9a90-4ec6-b343-358f002045ab/overview)|***Not Used***|[kv-sbox-infra-bf04-uks](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/1a1077b6-9a90-4ec6-b343-358f002045ab/resourceGroups/rg-mgmt-sbox-infra-uks/providers/Microsoft.KeyVault/vaults/kv-sbox-infra-bf04-uks/overview) |[asdt-loganalytics-r932mriwsm](https://portal.azure.com/#@dev.iace.mod.gov.uk/resource/subscriptions/1a1077b6-9a90-4ec6-b343-358f002045ab/resourceGroups/asdt-audit/providers/Microsoft.OperationalInsights/workspaces/asdt-loganalytics-r932mriwsm/Overview) |sysadmin|KV/LAW located in INFRA sub | 



