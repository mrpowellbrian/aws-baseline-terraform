# ── S3 bucket ────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = local.cloudtrail_bucket_name

  # Prevent accidental destruction of audit logs.
  # Set to true only in ephemeral test environments.
  force_destroy = false

  tags = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.cloudtrail_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.cloudtrail_kms_key_arn
    }
    # bucket_key_enabled reduces KMS API calls by ~99% when using SSE-KMS.
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "expire-cloudtrail-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.cloudtrail_s3_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.cloudtrail]
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.cloudtrail_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  # CloudTrail must verify bucket ACL before it can write.
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_trail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_trail_name}"]
    }
  }

  # Enforce TLS for all S3 operations on this bucket.
  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.cloudtrail[0].arn, "${aws_s3_bucket.cloudtrail[0].arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ── CloudTrail trail ──────────────────────────────────────────────────────────

resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = local.cloudtrail_trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail[0].id

  # Capture IAM, STS, and other global service events in addition to regional.
  include_global_service_events = true

  # A multi-region trail records API activity across all regions into a single
  # S3 bucket, which is critical for detecting lateral movement.
  is_multi_region_trail = true

  enable_log_file_validation = var.cloudtrail_enable_log_file_validation

  kms_key_id     = var.cloudtrail_kms_key_arn
  sns_topic_name = var.enable_sns_alerts ? aws_sns_topic.alerts[0].arn : null

  tags = local.common_tags

  # Bucket policy and SNS topic policy must exist before the trail is created.
  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_sns_topic_policy.alerts,
  ]
}
