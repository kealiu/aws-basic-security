
#
# enable default config
#
resource "aws_iam_service_linked_role" "aws_config" {
  aws_service_name = "config.amazonaws.com"
}

resource "aws_config_configuration_recorder" "security_recorder" {
  name     = "security_recorder"
  role_arn = aws_iam_service_linked_role.aws_config.arn
}

resource "aws_config_delivery_channel" "security_delivery_channel" {
  name           = "security_delivery_channel"
  s3_bucket_name = var.aws_config_bucket_name
  depends_on     = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_configuration_recorder_status" "security_recorder" {
  name       = aws_config_configuration_recorder.security_recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.security_delivery_channel]
}

#
# config rules
#
# identity can be find in aws rule detail page
#
resource "aws_config_config_rule" "iam-password-policy" {
  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "cloudtrail-enabled" {
  name = "cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "securityhub-enabled" {
  name = "securityhub-enabled"

  source {
    owner             = "AWS"
    source_identifier = "SECURITYHUB_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "iam-user-mfa-enabled" {
  name = "iam-user-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "iam-root-access-key-check" {
  name = "iam-root-access-key-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "root-account-mfa-enabled" {
  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "iam-user-unused-credentials-check" {
  name = "iam-user-unused-credentials-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "security-account-information-provided" {
  name = "security-account-information-provided"

  source {
    owner             = "AWS"
    source_identifier = "SECURITY_ACCOUNT_INFORMATION_PROVIDED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "mfa-enabled-for-iam-console-access" {
  name = "mfa-enabled-for-iam-console-access"

  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "access-keys-rotated" {
  name = "access-keys-rotated"

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  input_parameters = jsonencode({
      maxAccessKeyAge = "90"
    })

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "api-gw-associated-with-waf" {
  name = "api-gw-associated-with-waf"

  source {
    owner             = "AWS"
    source_identifier = "API_GW_ASSOCIATED_WITH_WAF"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "alb-waf-enabled" {
  name = "alb-waf-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ALB_WAF_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}

resource "aws_config_config_rule" "guardduty-enabled-centralized" {
  name = "guardduty-enabled-centralized"

  source {
    owner             = "AWS"
    source_identifier = "GUARDDUTY_ENABLED_CENTRALIZED"
  }

  depends_on = [aws_config_configuration_recorder.security_recorder]
}