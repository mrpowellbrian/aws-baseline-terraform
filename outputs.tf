# ── CloudTrail ────────────────────────────────────────────────────────────────

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = var.enable_cloudtrail ? aws_cloudtrail.this[0].arn : null
}

output "cloudtrail_s3_bucket_name" {
  description = "Name of the S3 bucket receiving CloudTrail logs."
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

# ── SNS ───────────────────────────────────────────────────────────────────────

output "sns_topic_arn" {
  description = "ARN of the security alerts SNS topic."
  value       = var.enable_sns_alerts ? aws_sns_topic.alerts[0].arn : null
}

# ── GuardDuty ─────────────────────────────────────────────────────────────────

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector."
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
}

# ── AWS Config ────────────────────────────────────────────────────────────────

output "config_recorder_id" {
  description = "ID of the AWS Config configuration recorder."
  value       = var.enable_aws_config ? aws_config_configuration_recorder.this[0].id : null
}

output "config_s3_bucket_name" {
  description = "Name of the S3 bucket receiving AWS Config snapshots."
  value       = var.enable_aws_config ? aws_s3_bucket.config[0].id : null
}
