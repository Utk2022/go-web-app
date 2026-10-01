data "aws_caller_identity" "current" {}

locals {
  bucket_name = lower(
    "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
  )
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name

  # Prevent accidental deletion of the state bucket.
  force_destroy = false

  tags = {
    Name        = local.bucket_name
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "Terraform remote state"
    Environment = "bootstrap"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "terraform_state" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state.json

  depends_on = [
    aws_s3_bucket_public_access_block.terraform_state
  ]
}
