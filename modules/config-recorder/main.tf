terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "bucket_name" {
  type = string
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "recorder" {
  name               = "config-recorder-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "recorder" {
  role       = aws_iam_role.recorder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  name     = "org-config-recorder"
  role_arn = aws_iam_role.recorder.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "org-config-delivery"
  s3_bucket_name = var.bucket_name

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}