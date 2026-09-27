resource "aws_organizations_delegated_administrator" "config" {
  account_id        = aws_organizations_account.audit_security.id
  service_principal = "config.amazonaws.com"
}
