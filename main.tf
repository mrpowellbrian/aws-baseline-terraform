# Resources are implemented in focused files:
#   cloudtrail.tf  – trail, S3 bucket, bucket policy
#   config.tf      – recorder, delivery channel, managed rules, S3 bucket
#   guardduty.tf   – detector
#   iam.tf         – account password policy
#   s3.tf          – account-level public access block
#   sns.tf         – security alerts topic

locals {
  # Merged tag map used wherever resource-level tags are needed.
  # The AWS provider default_tags block (set by the caller) covers everything;
  # this local lets submodule resources add per-resource overrides cleanly.
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "aws-baseline-terraform"
  })
}
