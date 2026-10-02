resource "aws_organizations_delegated_administrator" "config" {
  account_id        = aws_organizations_account.audit_security.id
  service_principal = "config.amazonaws.com"
}

resource "aws_s3_bucket" "config_logs" {
  provider      = aws.audit_security
  bucket        = "landingzone-config-logs-746760141143"
  force_destroy = false

  tags = {
    Purpose = "AWS Config recorder storage"
  }
}

resource "aws_s3_bucket_versioning" "config_logs" {
  provider = aws.audit_security
  bucket   = aws_s3_bucket.config_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "config_logs" {
  provider = aws.audit_security
  bucket   = aws_s3_bucket.config_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
data "aws_iam_policy_document" "config_bucket_policy" {
  provider = aws.audit_security

  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.config_logs.arn]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config_logs.arn}/AWSLogs/746760141143/Config/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_logs" {
  provider = aws.audit_security
  bucket   = aws_s3_bucket.config_logs.id
  policy   = data.aws_iam_policy_document.config_bucket_policy.json
}

data "aws_iam_policy_document" "config_assume_role" {
  provider = aws.audit_security

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_recorder" {
  provider           = aws.audit_security
  name               = "config-recorder-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
}

resource "aws_iam_role_policy_attachment" "config_recorder" {
  provider   = aws.audit_security
  role       = aws_iam_role.config_recorder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}
