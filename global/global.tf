# region will be set to 'us-east-1'

# ${data.aws_partition.current.partition}  , for `ARN`
data "aws_partition" "current" {}

# ${data.aws_region.current.name}
data "aws_region" "current" {}

# ${data.aws_caller_identity.current.account_id}
data "aws_caller_identity" "current" {}

#
# IAM user password policy
#
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 8
  max_password_age               = 90
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 3
}

#
# S3 bucket for cloudtrail and AWS config
#

resource "aws_s3_bucket" "cnofig_bucket" {
  bucket = var.aws_config_bucket_name

}

resource "aws_s3_bucket_versioning" "cloudtrail_and_config_version" {
  bucket = aws_s3_bucket.cnofig_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_and_config_policy" {
  bucket = aws_s3_bucket.cnofig_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_and_config_policy.json
}

data "aws_iam_policy_document" "cloudtrail_and_config_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck-${data.aws_caller_identity.current.account_id}-${var.random_str}"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cnofig_bucket.arn]
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite-${data.aws_caller_identity.current.account_id}-${var.random_str}"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cnofig_bucket.arn}/*"]

    condition {
      test     = "StringLike"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }

  statement {
    sid = "AWSCondfigPolicy-${data.aws_caller_identity.current.account_id}-${var.random_str}"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.cnofig_bucket.arn,
      "${aws_s3_bucket.cnofig_bucket.arn}/*",
    ]
  }
}

# resource "aws_s3_bucket_object_lock_configuration" "object_lock" {
#   bucket = aws_s3_bucket.cnofig_bucket.id
#   rule {
#     default_retention {
#       mode = "COMPLIANCE"
#       days = 180
#     }
#   }
#   depends_on = [aws_s3_bucket_versioning.cloudtrail_and_config_version]
# }

output "cnofig_bucket_arn" {
  value =  aws_s3_bucket.cnofig_bucket.arn
}

#
# for iam events
#

resource "aws_sns_topic" "iam_events" {
  name = "iam-events-topic"
}

resource "aws_sns_topic_policy" "iam_events" {
  arn = aws_sns_topic.iam_events.arn
  policy = data.aws_iam_policy_document.iam_events_policy.json
}

data "aws_iam_policy_document" "iam_events_policy" {
  policy_id = "__default_policy_ID"
  
  statement {
    sid = "allow_sns_public_of_event_bridge"
    actions = ["sns:Publish"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.iam_events.arn,
    ]
  }

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.iam_events.arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_subscription" "admin_notification" {
  topic_arn = aws_sns_topic.iam_events.arn
  protocol  = "email"
  for_each = toset(var.admin_email)
  endpoint  = each.value
}

# rule for IAM user event @ event bridge
resource "aws_cloudwatch_event_rule" "iam_event" {
  name        = "user_create_or_delete"
  description = "Capture iam user events"

  event_pattern = jsonencode({
    "source": [
        "aws.iam"
    ],
    "detail-type": [
        "AWS API Call via CloudTrail"
    ],
    "detail": {
        "eventSource": [
        "iam.amazonaws.com"
        ],
        "eventName": [
        "CreateUser",
        "DeleteUser"
        ]
    }
    })
}

resource "aws_cloudwatch_event_target" "iam_event_notify" {
  rule      = aws_cloudwatch_event_rule.iam_event.name
  target_id = "iam_event_notify"
  arn       = aws_sns_topic.iam_events.arn
}
