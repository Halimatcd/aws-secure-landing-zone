resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "log_archive" {
  name              = "log-archive"
  email             = "aminuoluwatosin2000+logarchive@gmail.com"
  parent_id         = aws_organizations_organizational_unit.security.id
  close_on_deletion = false

  tags = {
    Purpose = "Centralized log storage"
  }
}

resource "aws_organizations_account" "audit_security" {
  name              = "audit-security"
  email             = "aminuoluwatosin2000+audit@gmail.com"
  parent_id         = aws_organizations_organizational_unit.security.id
  close_on_deletion = false

  tags = {
    Purpose = "Delegated security administration for GuardDuty Security Hub Config and Access Analyzer"
  }
}

resource "aws_organizations_account" "workload_dev" {
  name              = "workload-dev"
  email             = "aminuoluwatosin2000+workload@gmail.com"
  parent_id         = aws_organizations_organizational_unit.workloads.id
  close_on_deletion = false

  tags = {
    Purpose = "Sample workload account"
  }
}

