# GitHub Actions OIDC provider.
#
# This allows GitHub Actions to exchange its short-lived OIDC
# identity token for temporary AWS credentials via STS.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(local.tags, {
    Component = "GitHubActionsOIDC"
  })
}


# --------------------------------------------------------------
# GitHub Actions OIDC subject
# --------------------------------------------------------------
locals {
  github_oidc_subject = var.github_use_immutable_oidc_subjects ? "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:ref:refs/heads/${var.github_branch}" : "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
}

# --------------------------------------------------------------
# Trust policy
# --------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid    = "GitHubActionsOIDC"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        local.github_oidc_subject
      ]
    }
  }
}


# --------------------------------------------------------------
# CI IAM role
# --------------------------------------------------------------

resource "aws_iam_role" "github_actions_ecr" {
  name = "${local.name}-github-actions-ecr"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  description = "GitHub Actions role for building and publishing the go-web-app image to ECR."

  max_session_duration = 3600

  tags = merge(local.tags, {
    Component = "GitHubActions"
  })
}


# --------------------------------------------------------------
# Least-privilege ECR policy
# --------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_ecr" {

  # ECR authentication token is a registry-level operation.
  # AWS requires "*" for this action.
  statement {
    sid    = "ECRAuthorization"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }


  # Everything else is restricted to THIS repository.
  statement {
    sid    = "ECRRepositoryAccess"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      aws_ecr_repository.go_web_app.arn
    ]
  }
}


resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${local.name}-github-actions-ecr"
  role = aws_iam_role.github_actions_ecr.id

  policy = data.aws_iam_policy_document.github_actions_ecr.json
}
