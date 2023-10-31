The Cert Generation process is only required for initial provisioning of the Application Gateway.

Self-signed TLS certificates are created and stored in the the MGMT key vault, so that the Application Gateway Listener rules creation has a TLS certificate to reference upon deployment.

Trusted certificates are provisioned once the cluster is up and running using the process detailed in the [Certificate provisioning](../../docs/certificates.md) process.

Only run this workflow as part of the  [Application Gateway deployment workflow](../deploy-az-app-gw.sh)