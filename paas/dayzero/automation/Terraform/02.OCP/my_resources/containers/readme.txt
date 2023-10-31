
skopeo copy docker://quay.io/gpte-devops-automation/gitea:latest dir:/home/adminuser/dso/cont_impex_1/gitea:latest

To copy and sign an image:
skopeo copy --sign-by dev@example.com containers-storage:example/busybox:streaming docker://example/busybox:gold

# To encrypt an image:
skopeo copy docker://docker.io/library/nginx:1.17.8 oci:local_nginx:1.17.8

openssl genrsa -out private.key 1024
openssl rsa -in private.key -pubout > public.key

skopeo  copy --encryption-key jwe:./public.key oci:local_nginx:1.17.8 oci:try-encrypt:encrypted

# To decrypt an image:
skopeo copy --decryption-key ./private.key oci:try-encrypt:encrypted oci:try-decrypt:decrypted

####### To copy lcoal directory image to quay:
skopeo copy dir:/home/adminuser/dso/cont_impex/vault docker://dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/vault-enterprise2:1.9.2-ent 

skopeo copy docker://hashicorp/vault-enterprise:1.11.1-ent docker://dso-quay-registry-quay-quay-enterprise.apps.ocp3.azure.dso.digital.mod.uk/dso-project/vault-enterprise:1.11.1-ent
