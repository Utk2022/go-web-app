data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-${var.environment}-aws-lbc"

  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-aws-lbc"
    Component   = "aws-load-balancer-controller"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "${var.project_name}-${var.environment}-aws-lbc-policy"

  policy = file("${path.module}/aws-load-balancer-controller-policy.json")

  tags = {
    Name        = "${var.project_name}-${var.environment}-aws-lbc-policy"
    Component   = "aws-load-balancer-controller"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"

  role_arn = aws_iam_role.aws_load_balancer_controller.arn
}
