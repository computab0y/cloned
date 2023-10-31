#!/bin/bash

set -x

ocp_instance="<ocp_inst>"
chmod +w $HOME/install-config.yaml
cp $HOME/install-config.yaml $HOME/ocp/$ocp_instance/
openshift-install version
openshift-install create manifests --dir $HOME/ocp/$ocp_instance/


cp -r $HOME/ocp/manifests $HOME/ocp/$ocp_instance
cd $HOME/ocp/$ocp_instance/manifests

quay_release=$(openshift-install version | grep 'release image' | awk '{  print $3 }')
oc adm release extract $quay_release --credentials-requests --cloud=azure

grep -l "release.openshift.io/feature-gate" * | xargs rm -f

# these vars should be setup as env variables to be used
sub_id="<sub_id>"
cli_id="<cli_id>"
cli_secret="<cli_secret>"
tenant_id="<tenant_id>"

res_prefix=$(grep 'infrastructureName: ' $HOME/ocp/$ocp_instance/manifests/cluster-infrastructure-02-config.yml | awk '{ print $2 }')
rg=$(grep 'resourceGroupName: ' $HOME/ocp/$ocp_instance/manifests/cluster-infrastructure-02-config.yml | awk '{ print $2 }')
region="uksouth"


sed -ri "s/<subscription-id>/${sub_id}/g" *.yaml
sed -ri "s/<client-id>/${cli_id}/g" *.yaml
sed -ri "s/<client-secret>/${cli_secret}/g" *.yaml
sed -ri "s/<tenant>/${tenant_id}/g" *.yaml
sed -ri "s/<infra-id>/${res_prefix}/g" *.yaml
sed -ri "s/<resource-group>/${rg}/g" *.yaml
sed -ri "s/<region>/${region}/g" *.yaml

