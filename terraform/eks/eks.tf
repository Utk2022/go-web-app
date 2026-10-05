module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.24.2"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  # ------------------------------------------------------------
  # Cluster lifecycle / upgrade behavior
  # ------------------------------------------------------------

  # STANDARD means the cluster will not enter paid extended
  # support when the current standard-support window ends.
  upgrade_policy = {
    support_type = "STANDARD"
  }

  deletion_protection = false

  # ------------------------------------------------------------
  # Authentication
  # ------------------------------------------------------------

  authentication_mode = "API"

  # Give the IAM identity running Terraform administrator access
  # through an EKS access entry.
  enable_cluster_creator_admin_permissions = true

  # ------------------------------------------------------------
  # Kubernetes API endpoint
  # ------------------------------------------------------------

  # Workers communicate with the API privately.
  endpoint_private_access = true

  # Your workstation/VM reaches kubectl through the public endpoint.
  endpoint_public_access = true

  # IMPORTANT:
  # terraform.tfvars will contain your public IP /32.
  endpoint_public_access_cidrs = [
    var.admin_cidr
  ]

  # ------------------------------------------------------------
  # Control-plane egress
  # ------------------------------------------------------------

  # AWS manages control-plane egress routing.
  # Therefore the control-plane subnets do not need a NAT path
  # for the EKS control plane itself.
  control_plane_egress_mode = "AWS_MANAGED"

  # ------------------------------------------------------------
  # Networking
  # ------------------------------------------------------------

  vpc_id = module.vpc.vpc_id

  # Worker/node subnets.
  subnet_ids = module.vpc.private_subnets

  # Dedicated control-plane ENI subnets.
  control_plane_subnet_ids = module.vpc.intra_subnets

  ip_family = "ipv4"

  # ------------------------------------------------------------
  # IAM / OIDC
  # ------------------------------------------------------------

  enable_irsa = true

  # ------------------------------------------------------------
  # Control-plane logs
  # ------------------------------------------------------------

  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 7

  # ------------------------------------------------------------
  # Cluster secret encryption
  # ------------------------------------------------------------

  create_kms_key                  = true
  enable_kms_key_rotation         = true
  kms_key_deletion_window_in_days = 7

  encryption_config = {
    resources = ["secrets"]
  }

  # ------------------------------------------------------------
  # EKS managed add-ons
  # ------------------------------------------------------------

  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true

      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }

    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }


    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
  }

  # ------------------------------------------------------------
  # Managed node groups
  # ------------------------------------------------------------

  eks_managed_node_groups = {
    general = {
      name = "${local.name}"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      disk_size = 20

      min_size     = var.node_group_min_size
      desired_size = var.node_group_desired_size
      max_size     = var.node_group_max_size

      update_config = {
        max_unavailable = 1
      }
      node_repair_config = {
        enabled = true
      }

      labels = {
        workload = "general"
      }

      tags = {
        NodeGroup = "general"
      }
    }
  }

  tags = local.tags

}
