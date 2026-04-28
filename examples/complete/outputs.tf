output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = module.baseline.cloudtrail_arn
}

output "cloudtrail_s3_bucket_name" {
  description = "S3 bucket receiving CloudTrail logs."
  value       = module.baseline.cloudtrail_s3_bucket_name
}

output "sns_topic_arn" {
  description = "ARN of the security alerts SNS topic. Wire subscriptions here."
  value       = module.baseline.sns_topic_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID."
  value       = module.baseline.guardduty_detector_id
}

output "config_recorder_id" {
  description = "AWS Config recorder ID."
  value       = module.baseline.config_recorder_id
}

output "config_s3_bucket_name" {
  description = "S3 bucket receiving AWS Config snapshots."
  value       = module.baseline.config_s3_bucket_name
}
