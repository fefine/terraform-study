locals {
  profile         = "shaohua"
  cluster_name    = "test-eks"
  cluster_version = "1.17"

  ami_id_x86        = "ami-005c06c6de69aee84"
  instance_type_x86 = "t2.micro"

  ami_id_aarch        = "ami-05a47ebfed89cca5a"
  instance_type_aarch = "t4g.nano"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id # import cluster
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}

# security group
resource "aws_security_group" "worker_group" {
  description = "Created for eks worker"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
  # default
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
}

# create vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name = "test-eks-vpc"
  cidr = "172.16.0.0/16"
  azs  = data.aws_availability_zones.available.names # A list of availability zones names or ids in the region
  # network
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# create eks
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  subnets         = module.vpc.private_subnets
  tags = {
    Environment = "dev"
  }
  # vpc
  vpc_id = module.vpc.vpc_id
  # ec2
  worker_groups = [
    {
      name                 = "workers-x86"
      instance_type        = local.instance_type_x86
      ami_id               = local.ami_id_x86
      asg_desired_capacity = 2 # auto scalling group: 2 ec2
      # additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                 = "workers-aarch"
      instance_type        = local.instance_type_aarch
      ami_id               = local.ami_id_aarch
      asg_desired_capacity = 1
    },
  ]
  # workers security group
  worker_additional_security_group_ids = [aws_security_group.worker_group.id]

  # add additional iam user/role/account (optional)
  # map_roles                            = var.map_roles
  # map_users                            = var.map_users
  # map_accounts                         = var.map_accounts
}
