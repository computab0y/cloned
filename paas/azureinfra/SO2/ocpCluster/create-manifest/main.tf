resource "null_resource" "tar_manifests" {
  provisioner "local-exec" {
    command = "tar -cf ../manifests.tar ../manifests/*"   
  }
}