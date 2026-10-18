resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = aws_organizations_account.audit_security.id

  depends_on = [aws_organizations_organization.this]
}

data "aws_guardduty_detector" "audit" {
  provider = aws.audit_security

  depends_on = [aws_guardduty_organization_admin_account.this]
}

resource "aws_guardduty_organization_configuration" "this" {
  provider                         = aws.audit_security
  detector_id                      = data.aws_guardduty_detector.audit.id
  auto_enable_organization_members = "ALL"
}
