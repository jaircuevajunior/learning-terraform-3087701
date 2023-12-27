data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

data "aws_vpc" "default" {
  default = true
}

module "blog_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"

  name = var.env.name
  cidr = "${var.env.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.env.network_prefix}.101.0/24", "${var.env.network_prefix}.102.0/24", "${var.env.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.env.name
  }
}

module "blog_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.3.1"

  # Autoscaling group
  name = "${var.env.name}-blog_asg"

  min_size                  = var.asg_settings.min_size
  max_size                  = var.asg_settings.max_size
  desired_capacity          = var.asg_settings.desired_capacity
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.blog_vpc.public_subnets

  # Launch template
  launch_template_name        = "blog_lt"
  launch_template_description = "Launch template example"
  update_default_version      = true

  image_id          = data.aws_ami.app_ami.id
  instance_type     = var.instance_type
  ebs_optimized     = true
  enable_monitoring = true

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "example-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.blog_sg.security_group_id]
    }
  ]

  placement = {
    availability_zone = "us-west-1a"
  }

  target_group_arns = [module.blog_alb.target_groups.ex-instance.id]

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = {
        WhatAmI = "Instance"
      }
    },
    {
      resource_type = "volume"
      tags          = { WhatAmI = "Volume" }
    }
  ]

  tags = {
    Environment = "dev"
  }
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.4.0"

  name            = "${var.env.name}-blog-alb"
  vpc_id          = module.blog_vpc.vpc_id
  subnets         = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]
  
  enable_deletion_protection = false

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix       = "${var.env.name}-"
      protocol          = "HTTP"
      port              = 80
      create_attachment = false
    }
  }
  
  tags = {
    Environment = var.env.name
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name = "${var.env.name}-blog_sg"

  vpc_id = module.blog_vpc.vpc_id
  
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

}