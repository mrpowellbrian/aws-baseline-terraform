# Complete example — every variable shown explicitly so consumers can see
# exactly what's available and which values differ from the defaults.
#
# To apply:
#   terraform init
#   terraform plan
#   terraform apply

module "baseline" {
  # In real usage, pin to a specific tag or commit SHA:
  #   source = "github.com/mrpowellbrian/aws-baseline-terraform?ref=v1.0.0"
  source = "../../"

  name_prefix = "acme-prod"

  # ── Feature toggles ──────────────────────────────────────────────────────
  # All default to true. Set to false in sandbox/dev accounts to reduce cost.
  enable_cloudtrail             = true
  enable_aws_config             = true
  enable_guardduty              = true
  enable_iam_password_policy    = true
  enable_s3_public_access_block = true
  enable_sns_alerts             = true

  # ── Tagging ───────────────────────────────────────────────────────────────
  tags = {
    CostCenter  = "platform-shared"
    DataClass   = "restricted"
  }

  # ── CloudTrail ────────────────────────────────────────────────────────────
  cloudtrail_s3_retention_days          = 365
  cloudtrail_enable_log_file_validation = true

  # Uncomment to encrypt CloudTrail and Config logs with a customer-managed key:
  # cloudtrail_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  # ── AWS Config ────────────────────────────────────────────────────────────
  config_delivery_frequency = "TwentyFour_Hours"

  # Remove rules that aren't relevant to your account, or add custom ones.
  config_managed_rules = [
    "S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",
    "ENCRYPTED_VOLUMES",
    "IAM_PASSWORD_POLICY",
    "IAM_ROOT_ACCESS_KEY_CHECK",
    "CLOUD_TRAIL_ENABLED",
    "GUARDDUTY_ENABLED_CENTRALIZED",
    "VPC_DEFAULT_SECURITY_GROUP_CLOSED",
    "ACCESS_KEYS_ROTATED",
  ]

  # ── IAM password policy ───────────────────────────────────────────────────
  iam_password_min_length       = 16
  iam_password_max_age_days     = 90
  iam_password_reuse_prevention = 24
}
