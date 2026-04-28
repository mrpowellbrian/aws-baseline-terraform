# ── Feature toggles ──────────────────────────────────────────────────────────

variable "enable_cloudtrail" {
  description = "Create a multi-region CloudTrail trail with S3 log delivery."
  type        = bool
  default     = true
}

variable "enable_aws_config" {
  description = "Enable AWS Config recorder and deploy the baseline managed rules."
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty detector. Disable to avoid cost in non-production accounts."
  type        = bool
  default     = true
}

variable "enable_iam_password_policy" {
  description = "Apply an account-level IAM password policy."
  type        = bool
  default     = true
}

variable "enable_s3_public_access_block" {
  description = "Apply account-level S3 Block Public Access settings."
  type        = bool
  default     = true
}

variable "enable_sns_alerts" {
  description = "Create an SNS topic for security alert notifications."
  type        = bool
  default     = true
}

# ── Naming & tagging ─────────────────────────────────────────────────────────

variable "name_prefix" {
  description = "Short prefix applied to every resource name. Allows multiple instances in one account."
  type        = string
  default     = "baseline"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.name_prefix))
    error_message = "name_prefix must be 1–20 lowercase alphanumeric characters or hyphens."
  }
}

variable "tags" {
  description = "Tags merged into the AWS provider default_tags block and applied to every resource."
  type        = map(string)
  default     = {}
}

# ── CloudTrail ────────────────────────────────────────────────────────────────

variable "cloudtrail_s3_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3 before expiration."
  type        = number
  default     = 365

  validation {
    condition     = var.cloudtrail_s3_retention_days >= 90
    error_message = "Retention must be at least 90 days to satisfy common compliance baselines."
  }
}

variable "cloudtrail_enable_log_file_validation" {
  description = "Enable CloudTrail log file integrity validation."
  type        = bool
  default     = true
}

# ── AWS Config ────────────────────────────────────────────────────────────────

variable "config_managed_rules" {
  description = <<-EOT
    List of AWS Config managed rule identifiers to deploy.
    Only rules from the curated default set are supported without additional input_parameters work.
  EOT
  type        = list(string)
  default = [
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
}

variable "config_delivery_frequency" {
  description = "How often AWS Config delivers configuration snapshots to S3. One of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  type        = string
  default     = "TwentyFour_Hours"

  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.config_delivery_frequency)
    error_message = "config_delivery_frequency must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }
}

# ── IAM password policy ───────────────────────────────────────────────────────

variable "iam_password_min_length" {
  description = "Minimum IAM password length."
  type        = number
  default     = 16
}

variable "iam_password_max_age_days" {
  description = "Maximum IAM password age in days before rotation is required. Set to 0 to disable expiry."
  type        = number
  default     = 90
}

variable "iam_password_reuse_prevention" {
  description = "Number of previous passwords that IAM users are prevented from reusing."
  type        = number
  default     = 24
}
