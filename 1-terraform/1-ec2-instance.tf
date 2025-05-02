# aws ssm start-session --target i-0353e418fbe8d3367 --region eu-west-1
module "ec2_complete" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.8.0"

  name = local.name

  ami                    = data.aws_ami.amazon_linux_23.id
  instance_type          = "c5.xlarge" # used to set core count below
  # availability_zone      = element(module.vpc.azs, 0)
  # subnet_id              = element(module.vpc.private_subnets, 0)
  availability_zone      = "eu-west-1a"
  subnet_id              = "subnet-0f0e543c4bd28d9dd"
  vpc_security_group_ids = [module.security_group.security_group_id]
  placement_group        = aws_placement_group.web.id
  create_eip             = false
  disable_api_stop       = false

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  # only one of these can be enabled at a time
  hibernation = true
  # enclave_options_enabled = true

  user_data_base64            = filebase64("${path.cwd}/config/user_data/ec2.sh")
  user_data_replace_on_change = true
  cpu_options = {
    core_count       = 2
    threads_per_core = 1
  }
  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
      tags = {
        Name = "my-root-block"
      }
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 5
      throughput  = 200
      encrypted   = true
      kms_key_id  = aws_kms_key.this.arn
      tags = {
        MountPoint = "/mnt/data"
      }
    }
  ]
  tags = merge(
    local.tags,
    {
      ccoe_http_proxy = "http://cirrus-proxy.shared-services.local:8080"
      ccoe_https_proxy = "http://cirrus-proxy.shared-services.local:8080"
    }
  )
}


################################################################################
# Supporting Resources
################################################################################
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"

#   name = local.name
#   cidr = local.vpc_cidr

#   azs             = local.azs
#   private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
#   public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

#   tags = local.tags
# }

data "aws_ami" "amazon_linux_23" {
  most_recent = true
  owners      = ["737787953020"]

  filter {
    name   = "name"
    # values = ["al2023-ami-2023*-x86_64"]
    values = ["PROD-Amazon-Linux-2023-Dec-2024"]
  }
}
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn-ami-hvm-*-x86_64-gp2"]
#   }
# }

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"
  name        = local.name
  description = "Security group for example usage with EC2 instance"
  # vpc_id      = module.vpc.vpc_id
  vpc_id      = "vpc-091f24c021616d3e7"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Jenkins Port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      description = "SonarQube Port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_rules        = ["all-all"]
  tags = local.tags
}

resource "aws_placement_group" "web" {
  name     = local.name
  strategy = "cluster"
}

resource "aws_kms_key" "this" {
}

resource "aws_network_interface" "this" {
  # subnet_id = element(module.vpc.private_subnets, 0)
  subnet_id = "subnet-0f0e543c4bd28d9dd"
}