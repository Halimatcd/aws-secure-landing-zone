# ============================================================
# KMS Key - encrypts CloudTrail logs at rest in Log Archive account
# ============================================================

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
    sid    = "AllowCloudTrailEncryptLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:us-east-1:955364210974:trail/org-landingzone-trail"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:955364210974:trail/*"]
    }
  }

  statement {
    sid    = "AllowCloudTrailDecryptTrail"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:us-east-1:955364210974:trail/org-landingzone-trail"]
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

# ============================================================
# S3 Bucket - stores CloudTrail logs in Log Archive account
# ============================================================

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

# ============================================================
# S3 Bucket Policy - grants CloudTrail write access, denies deletion
#
# Note: the trail ARN below is constructed manually (not referenced
# via aws_cloudtrail.org_trail.arn) to avoid a circular dependency -
# the trail depends on this policy existing first, so this policy
# cannot in turn depend on the trail's computed output. We know the
# ARN in advance because we control the trail's name and account ID.
# ============================================================

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  provider = aws.log_archive

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:us-east-1:955364210974:trail/org-landingzone-trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = [
	"${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/955364210974/*",
	"${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/o-77d9ezfr6p/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:us-east-1:955364210974:trail/org-landingzone-trail"]
    }
  }

  statement {
    sid    = "DenyObjectDeletion"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:DeleteObject",
      "s3:DeleteBucket",
    ]
    resources = [
      aws_s3_bucket.cloudtrail_logs.arn,
      "${aws_s3_bucket.cloudtrail_logs.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  provider = aws.log_archive
  bucket   = aws_s3_bucket.cloudtrail_logs.id
  policy   = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

# ============================================================
# CloudTrail - org-wide trail, management account
# ============================================================

resource "aws_cloudtrail" "org_trail" {
  name                        = "org-landingzone-trail"
  s3_bucket_name              = aws_s3_bucket.cloudtrail_logs.id
  is_organization_trail       = true
  is_multi_region_trail       = true
  enable_log_file_validation  = true
  kms_key_id                  = aws_kms_key.cloudtrail_logs.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]

  tags = {
    Purpose = "Org-wide centralized audit logging"
  }
}
