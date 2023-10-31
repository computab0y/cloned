#Update the Azure App Gateway with an updated Certificate

1. Upload the renewed certificate to the Certificate in Key Vault by adding a New Version

2. Run the update script
```
cd azureinfra/SO1/app-gw/add-listener-alt-domain

./listener-update-kv-cert.sh -a dev-sb-service-mod-uk -b dev-sb-service-mod-uk-lstn -z 3
```

If there are any errors, the fix is to delete the Certificate from the Listener before running.

1. In the Azure Portal, switch the Listener to any other Certificate, e.g. ocp3-cert-apps

2. Delete the Certificate
```
az network application-gateway ssl-cert delete -g rg-ocp3mgmt-sbox-uks --gateway-name appgw-ocp3-sbox-uks -n dev-sb-service-mod-uk
```
3. Run the update again
```
./listener-update-kv-cert.sh -a dev-sb-service-mod-uk -b dev-sb-service-mod-uk-lstn -z 3
```