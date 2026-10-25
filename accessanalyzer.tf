resource "aws_organizations_delegated_administrator" "access_analyzer" {
  account_id        = aws_organizations_account.audit_security.id
  service_principal = "access-analyzer.amazonaws.com"
}

# Access Analyzer requires its service-linked role to exist in the
# management account before an organization analyzer can be created.
resource "aws_iam_service_linked_role" "access_analyzer" {
  aws_service_name = "access-analyzer.amazonaws.com"
}

resource "aws_accessanalyzer_analyzer" "org" {
  provider      = aws.audit_security
  analyzer_name = "org-external-access-analyzer"
  type          = "ORGANIZATION"

  depends_on = [
    aws_organizations_delegated_administrator.access_analyzer,
    aws_iam_service_linked_role.access_analyzer,
  ]
}
