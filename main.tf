#Outputs to pass to root
output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "ngw-id" {
  value = aws_nat_gateway.ngw.id
}

output "subnet_private" {
  value = aws_subnet.subnet_private.id
}

output "subnet_public1" {
  value = aws_subnet.subnet_public1.id
}

output "subnet_public2" {
  value = aws_subnet.subnet_public2.id
}
######################################
#VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ec2-nginx-lb"
  }
}

#Public Subnet #1
resource "aws_subnet" "subnet_public1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

#Public Subnet #2
resource "aws_subnet" "subnet_public2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}

#Private Subnet
resource "aws_subnet" "subnet_private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2b"
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#NAT Gateway - Public Subnet
resource "aws_eip" "nat_gateway" {
  domain                    = "vpc"
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.subnet_public1.id
  depends_on    = [aws_eip.nat_gateway]
}

#ROUTE - Subnets
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
}
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id
}

#Route Public Subnet to IGW
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

#Route Private Subnet to NGW
resource "aws_route" "private-internet-ngw-route" {
  route_table_id         = aws_route_table.private-rt.id
  nat_gateway_id         = aws_nat_gateway.ngw.id
  destination_cidr_block = "0.0.0.0/0"
}

#Route Table to Subnets
resource "aws_route_table_association" "public-rta1" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.subnet_public1.id
}

#Route Table to Subnets
resource "aws_route_table_association" "public-rta2" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.subnet_public2.id
}

resource "aws_route_table_association" "private-rta" {
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.subnet_private.id
}

