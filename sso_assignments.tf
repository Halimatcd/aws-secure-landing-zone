locals {
  sso_instance_arn         = "arn:aws:sso:::instance/ssoins-example"
  admin_permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-example/ps-example"
  sso_user_id              = "00000000-0000-0000-0000-000000000000"

  sso_member_accounts = {
    log_archive    = aws_organizations_account.log_archive.id
    audit_security = aws_organizations_account.audit_security.id
    workload_dev   = aws_organizations_account.workload_dev.id
  }
}

resource "aws_ssoadmin_account_assignment" "admin" {
  provider = aws.ca_central
  for_each = local.sso_member_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = local.admin_permission_set_arn

  principal_id   = local.sso_user_id
  principal_type = "USER"

  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}
