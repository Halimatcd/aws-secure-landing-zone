resource "aws_securityhub_organization_admin_account" "this" {
  admin_account_id = aws_organizations_account.audit_security.id

  depends_on = [aws_organizations_organization.this]
}

resource "aws_securityhub_account" "audit" {
  provider                 = aws.audit_security
  enable_default_standards = false

  depends_on = [aws_securityhub_organization_admin_account.this]
}

resource "aws_securityhub_account" "management" {
  enable_default_standards = false

  depends_on = [aws_securityhub_organization_admin_account.this]
}

resource "aws_securityhub_organization_configuration" "this" {
  provider              = aws.audit_security
  auto_enable           = true
  auto_enable_standards = "DEFAULT"

  depends_on = [aws_securityhub_account.audit]
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  provider      = aws.audit_security
  standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.audit]
}

resource "aws_securityhub_standards_subscription" "cis" {
  provider      = aws.audit_security
  standards_arn = "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0"

  depends_on = [aws_securityhub_account.audit]
}

resource "aws_securityhub_member" "log_archive" {
  provider   = aws.audit_security
  account_id = aws_organizations_account.log_archive.id
  invite     = true

  depends_on = [aws_securityhub_organization_configuration.this]
}

resource "aws_securityhub_member" "workload_dev" {
  provider   = aws.audit_security
  account_id = aws_organizations_account.workload_dev.id
  invite     = true

  depends_on = [aws_securityhub_organization_configuration.this]
}

resource "aws_securityhub_member" "management" {
  provider   = aws.audit_security
  account_id = aws_organizations_organization.this.master_account_id

  depends_on = [
    aws_securityhub_organization_configuration.this,
    aws_securityhub_account.management,
  ]
}
