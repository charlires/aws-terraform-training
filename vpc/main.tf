terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_security_group" "default" {
  name   = "allow_http_https_ssh"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
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

  tags = {
    Name = "allow_http_https_ssh"
  }

  depends_on = [ aws_vpc.main ]
}

// key_pair to connect to the instances
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.aws_ec2_key_pair
}

// public
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
  depends_on = [ aws_vpc.main ]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
  depends_on = [ aws_vpc.main ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }

  depends_on = [ aws_vpc.main, aws_subnet.public, aws_internet_gateway.igw ]
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_instance" "public" {
  ami           = "ami-047a51fa27710816e"
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.public.id
  security_groups             = [aws_security_group.default.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "public-instance"
  }

  depends_on = [ aws_subnet.public, aws_security_group.default, aws_key_pair.deployer ]
}

// ping google.com
output "public_instance_public_ip" {
  value = "ssh ec2-user@${aws_instance.public.public_ip}"
}

// private
# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1b"

#   tags = {
#     Name = "private-subnet"
#   }
# }

# // pass private key to public instance and give chmod 400 
# resource "aws_instance" "private" {
#   ami           = "ami-047a51fa27710816e"
#   instance_type = "t2.micro"

#   subnet_id       = aws_subnet.private.id
#   security_groups = [aws_security_group.default.name]
#   key_name        = aws_key_pair.deployer.key_name

#   tags = {
#     Name = "private-instance"
#   }
# }

# output "private_instance_private_ip" {
#   value = "ssh ec2-user@${aws_instance.private.private_ip}"
# }