# Threat Model

Scope: the multi-account landing zone in this repo (management, log-archive, audit-security, workload-dev). Technique IDs are from MITRE ATT&CK for Cloud.

## Assets

- Audit evidence: CloudTrail logs and digests in the log-archive bucket
- Preventive guardrails: SCPs attached at the organization root
- Detective tooling: Config, GuardDuty, Security Hub, Access Analyzer
- Administrative access: IAM Identity Center and the root user

## Threats and controls

| # | Threat | ATT&CK | Control | Evidence |
|---|---|---|---|---|
| 1 | Attacker with admin in a member account stops or deletes CloudTrail to hide activity | T1562.008 | SCP `deny-cloudtrail-tampering` at root | Live test: explicit deny |
| 2 | Attacker deletes or overwrites logs in the bucket | T1070 | Separate log-archive account, versioning, bucket policy denying object deletion, Glacier lifecycle with no expiry | Policy review; management role could not read the bucket |
| 3 | Attacker alters logs without deleting them | T1070 | Log file validation (signed digests) | `validate-logs`: 27/27 digests, 220/220 logs valid |
| 4 | Attacker disables Config recording to hide resource changes | T1562.001 | SCP `deny-config-tampering` at root | Attached at root; not live-tested |
| 5 | Attacker runs resources in unused regions where nobody looks | T1535 | SCP `deny-non-approved-regions` (us-east-1 only, global services exempt) | Live test: explicit deny in eu-west-1, control call succeeded in us-east-1 |
| 6 | Misuse of member-account root credentials | T1078.004 | SCP `deny-root-user-actions` | Policy review and attachment; not live-tested |
| 7 | Theft of long-lived access keys | T1552.001, T1078.004 | Identity Center short-lived sessions; bootstrap IAM user's key deleted, console login disabled | `list-access-keys` returns empty |
| 8 | Resource shared outside the organization (bucket, KMS key, role) | T1530, T1537 | Org-wide Access Analyzer (external access) | Analyzer active; no seeded finding tested |
| 9 | Compromised workload behaving maliciously (credential abuse, crypto-mining, recon) | T1078.004, T1496 | GuardDuty with auto-enable for all members, findings aggregated in Security Hub | Enabled and verified; no simulated findings |
| 10 | Insecure configuration drifts in unnoticed | T1562 | Config recorders plus org aggregator, Security Hub FSBP and CIS v1.4.0 | Aggregator and standards verified |

## Residual risks

- SCPs never apply to the management account. Its access is limited to Identity Center plus a root user with MFA.
- Detective controls alert but do not block. Nothing routes findings to a human yet (no SNS or ticketing).
- A sufficiently privileged principal in log-archive could change the bucket policy or schedule KMS key deletion. Closing this would need an SCP protecting those specific actions.
- Single region for the log bucket: no cross-region replication.
- Identity Center has one administrator user. Loss of that account and the root MFA device would mean lockout.
- Test accounts are real AWS accounts. Teardown is documented, and account closure takes 90 days.

## Out of scope

Workload-level threats (application vulnerabilities, network design, data classification), and anything running inside the member accounts beyond what this repo deploys.