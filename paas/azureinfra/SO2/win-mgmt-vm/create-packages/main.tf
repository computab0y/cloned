data "archive_file" "data_backup" {
  type        = "zip"
  source_dir = "${path.module}/../${var.source_dir}"
  output_path = "${path.module}/../.tmp/packages.zip"
}