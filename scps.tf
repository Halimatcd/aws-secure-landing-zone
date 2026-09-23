# SCP: Deny disabling or deleting CloudTrail
data "aws_iam_policy_document" "deny_cloudtrail_tampering" {
  statement {
    sid    = "DenyCloudTrailStopOrDelete"
    effect = "Deny"

    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
    ]

    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_cloudtrail_tampering" {
  name        = "deny-cloudtrail-tampering"
  description = "Prevents stopping or deleting CloudTrail trails org-wide"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_cloudtrail_tampering.json
}

resource "aws_organizations_policy_attachment" "deny_cloudtrail_tampering_root" {
  policy_id = aws_organizations_policy.deny_cloudtrail_tampering.id
  target_id = aws_organizations_organization.this.roots[0].id
}

# SCP: Restrict actions to approved region(s) only
data "aws_iam_policy_document" "deny_non_approved_regions" {
  statement {
    sid    = "DenyNonApprovedRegions"
    effect = "Deny"

    not_actions = [
      "iam:*",
      "organizations:*",
      "route53:*",
      "cloudfront:*",
      "support:*",
      "budgets:*",
      "sts:*",
      "trustedadvisor:*",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["us-east-1"]
    }
  }
}

resource "aws_organizations_policy" "deny_non_approved_regions" {
  name        = "deny-non-approved-regions"
  description = "Restricts actions to us-east-1 only, excluding global services"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_non_approved_regions.json
}

resource "aws_organizations_policy_attachment" "deny_non_approved_regions_root" {
  policy_id = aws_organizations_policy.deny_non_approved_regions.id
  target_id = aws_organizations_organization.this.roots[0].id
}

# SCP: Deny disabling or deleting AWS Config
data "aws_iam_policy_document" "deny_config_tampering" {
  statement {
    sid    = "DenyConfigStopOrDelete"
    effect = "Deny"

    actions = [
      "config:StopConfigurationRecorder",
      "config:DeleteConfigurationRecorder",
      "config:DeleteDeliveryChannel",
    ]

    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_config_tampering" {
  name        = "deny-config-tampering"
  description = "Prevents stopping or deleting AWS Config recorders/delivery channels org-wide"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_config_tampering.json
}

resource "aws_organizations_policy_attachment" "deny_config_tampering_root" {
  policy_id = aws_organizations_policy.deny_config_tampering.id
  target_id = aws_organizations_organization.this.roots[0].id
}

# SCP: Deny root user actions except a small necessary allowlist
data "aws_iam_policy_document" "deny_root_user" {
  statement {
    sid    = "DenyRootUserActions"
    effect = "Deny"

    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:root"]
    }
  }
}

resource "aws_organizations_policy" "deny_root_user" {
  name        = "deny-root-user-actions"
  description = "Blocks root user from performing any action in member accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_root_user.json
}

resource "aws_organizations_policy_attachment" "deny_root_user_root" {
  policy_id = aws_organizations_policy.deny_root_user.id
  target_id = aws_organizations_organization.this.roots[0].id
}
