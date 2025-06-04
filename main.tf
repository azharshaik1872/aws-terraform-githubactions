provider "aws" {
  region     = "us-east-1"
}

#1.Create VPC
resource "aws_vpc" "lab" {
  cidr_block       = "10.0.0.0/16"
    tags = {
    Name = "Lab VPC"
  }
}


