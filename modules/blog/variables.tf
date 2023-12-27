variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}


variable "ami_filter" {
  description = "Filters AMI by name and owner"

  type = object({
    name  = string
    owner = string
  })

  default = {
    name  = "bitnami-tomcat-*-x86_64-hvm-ebs-nami",
    owner = "979382823631"
  }
}

variable "env" {
  description = "Environment"

  type = object({
    name           = string
    network_prefix = string
  })

  default = {
    name           = "dev"
    network_prefix = "10.0"
  }
}

variable "asg_settings" {
  description = "Sizing settings for the ASG"

  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })

  default = {
    min_size         = 1
    max_size         = 2
    desired_capacity = 2
  }
}
