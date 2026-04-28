# ── IAM role for Config recorder ─────────────────────────────────────────────

data "aws_iam_policy_document" "config_assume_role" {
  count = var.enable_aws_config ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config" {
  count = var.enable_aws_config ? 1 : 0

  name               = "${var.name_prefix}-config-recorder"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role[0].json

  tags = local.common_tags
}

# AWS-managed policy granting Config read access to all supported resource types.
resource "aws_iam_role_policy_attachment" "config_managed" {
  count = var.enable_aws_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "config_s3_write" {
  count = var.enable_aws_config ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.config[0].arn]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_iam_role_policy" "config_s3_write" {
  count = var.enable_aws_config ? 1 : 0

  name   = "${var.name_prefix}-config-s3-delivery"
  role   = aws_iam_role.config[0].id
  policy = data.aws_iam_policy_document.config_s3_write[0].json
}

# ── S3 bucket for Config snapshots ───────────────────────────────────────────

resource "aws_s3_bucket" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket        = local.config_bucket_name
  force_destroy = false

  tags = local.common_tags
}

resource "aws_s3_bucket_ownership_controls" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.cloudtrail_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.cloudtrail_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket = aws_s3_bucket.config[0].id
  policy = data.aws_iam_policy_document.config_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.config]
}

data "aws_iam_policy_document" "config_bucket" {
  count = var.enable_aws_config ? 1 : 0

  statement {
    sid    = "AWSConfigAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AWSConfigWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.config[0].arn, "${aws_s3_bucket.config[0].arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ── Config recorder ───────────────────────────────────────────────────────────

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_aws_config ? 1 : 0

  name     = "${var.name_prefix}-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Delivery channel must exist before the recorder can be enabled.
resource "aws_config_delivery_channel" "this" {
  count = var.enable_aws_config ? 1 : 0

  name           = "${var.name_prefix}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config[0].id
  sns_topic_arn  = var.enable_sns_alerts ? aws_sns_topic.alerts[0].arn : null

  snapshot_delivery_properties {
    delivery_frequency = var.config_delivery_frequency
  }

  depends_on = [
    aws_config_configuration_recorder.this,
    aws_sns_topic_policy.alerts,
  ]
}

# Separate resource because enabling the recorder before the delivery channel
# exists causes a hard API error.
resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_aws_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

# ── Managed rules ─────────────────────────────────────────────────────────────

resource "aws_config_config_rule" "managed" {
  # toset deduplicates and converts the list to a map keyed by rule identifier.
  for_each = var.enable_aws_config ? toset(var.config_managed_rules) : toset([])

  name = "${var.name_prefix}-${lower(replace(each.key, "_", "-"))}"

  source {
    owner             = "AWS"
    source_identifier = each.key
  }

  # Rules require the recorder to be active before they can be created.
  depends_on = [aws_config_configuration_recorder_status.this]

  tags = local.common_tags
}
