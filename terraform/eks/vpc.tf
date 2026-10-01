module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs

  public_subnets = [
    "10.20.0.0/24",
    "10.20.1.0/24",
    "10.20.2.0/24"
  ]

  private_subnets = [
    "10.20.16.0/20",
    "10.20.32.0/20",
    "10.20.48.0/20"
  ]

  intra_subnets = [
    "10.20.64.0/28",
    "10.20.64.16/28",
    "10.20.64.32/28"
  ]

  enable_dns_hostnames   = true
  enable_dns_support     = true
  one_nat_gateway_per_az = false


  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  intra_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  tags = local.tags
}
