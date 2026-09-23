
data "aws_iam_policy_document" "cloudtrail_kms_key_policy" {
  provider = aws.log_archive

  statement {
    sid    = "EnableAccountKeyManagement"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::369992802183:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncrypt"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:955364210974:trail/*"]
    }
  }

  statement {
    sid    = "AllowCloudTrailDecrypt"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:955364210974:trail/*"]
    }
  }
}

resource "aws_kms_key" "cloudtrail_logs" {
  provider = aws.log_archive

  description             = "Encrypts org-wide CloudTrail logs in Log Archive account"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cloudtrail_kms_key_policy.json

  tags = {
    Purpose = "CloudTrail log encryption"
  }
}

resource "aws_kms_alias" "cloudtrail_logs" {
  provider      = aws.log_archive
  name          = "alias/cloudtrail-logs"
  target_key_id = aws_kms_key.cloudtrail_logs.key_id
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  provider      = aws.log_archive
  bucket        = "landingzone-cloudtrail-logs-369992802183"
  force_destroy = false

  tags = {
    Purpose = "Centralized CloudTrail log storage"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail_logs.arn
    }
    bucket_key_enabled = true
  }
}
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
