terraform {
  backend "s3" {
    bucket       = "go-web-app-sre-tfstate-891943684030-us-east-1"
    key          = "eks/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
