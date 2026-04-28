# Resources are implemented in focused files:
#   cloudtrail.tf  – trail, S3 bucket, bucket policy
#   config.tf      – recorder, delivery channel, managed rules, S3 bucket
#   guardduty.tf   – detector
#   iam.tf         – account password policy
#   s3.tf          – account-level public access block
#   sns.tf         – security alerts topic

locals {
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "aws-baseline-terraform"
  })

  cloudtrail_trail_name  = "${var.name_prefix}-trail"
  cloudtrail_bucket_name = "${var.name_prefix}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  config_bucket_name     = "${var.name_prefix}-config-snapshots-${data.aws_caller_identity.current.account_id}"
  sns_topic_name         = "${var.name_prefix}-security-alerts"
}
