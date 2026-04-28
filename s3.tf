resource "aws_s3_account_public_access_block" "this" {
  count = var.enable_s3_public_access_block ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
