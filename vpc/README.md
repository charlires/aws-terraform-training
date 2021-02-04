# Basic VPC setup

This terraform will create the follow resorces

- VPC with 10.0.0.0/16 cidr block
- Subnet with 10.0.1.0/24 cidr block in us-east-1a AZ
- Internet Gateway 
- Route table with 0.0.0.0/0 to internet gateway
- Route table subnet association
- EC2 Key pair
- Security Group allowing http https and ssh
- EC2 instance with public ip

Rename the `secrets.dist.tf` to `secrets.tf` and fill the variables