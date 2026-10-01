resource "aws_ecr_repository" "go_web_app" {
  name                 = "${local.name}/go-web-app"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.tags, {
    Component = "ContainerRegistry"
  })
}

resource "aws_ecr_lifecycle_policy" "go_web_app" {
  repository = aws_ecr_repository.go_web_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1

        description = "Expire untagged images after 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2

        description = "Keep the newest 30 images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}
