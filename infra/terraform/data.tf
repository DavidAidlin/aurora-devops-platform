#########################################
# Get default VPC
#########################################
data "aws_vpc" "default" {
  default = true
}

#########################################
# Get all subnets in the default VPC
#########################################
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#########################################
# Get Ubuntu 20.04 AMI
#########################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

