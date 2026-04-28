resource "aws_sns_topic" "alerts" {
  count = var.enable_sns_alerts ? 1 : 0

  name = local.sns_topic_name

  # Encrypt the topic at rest. Uses the AWS-managed SNS key by default;
  # pass var.cloudtrail_kms_key_arn if you want a customer-managed key.
  kms_master_key_id = coalesce(var.cloudtrail_kms_key_arn, "alias/aws/sns")

  tags = local.common_tags
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.enable_sns_alerts ? 1 : 0

  # Allow CloudTrail to publish notifications.
  statement {
    sid    = "AllowCloudTrailPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allow AWS Config to publish notifications.
  statement {
    sid    = "AllowConfigPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Deny non-TLS publishes.
  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts[0].arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.enable_sns_alerts ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}
