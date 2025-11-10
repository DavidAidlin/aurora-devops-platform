#############################################
# S3 Bucket for logs / reports
#############################################
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "aurora_logs" {
  bucket = "${var.environment_name}-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Project = "Aurora DevOps Platform"
  }
}

#############################################
# Security Group
#############################################
resource "aws_security_group" "aurora_sg" {
  name        = "${var.environment_name}-sg"
  description = "Security group for Aurora test environment"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow app traffic"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# EC2 Instance
#############################################
resource "aws_instance" "aurora_test_env" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  security_groups        = [aws_security_group.aurora_sg.id]
  key_name               = var.instance_key_name

  tags = {
    Name = "${var.environment_name}-instance"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip
  EOF
}
