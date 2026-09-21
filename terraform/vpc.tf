# 1. إنشاء VPC الرئيسي
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-app-vpc"
  }
}

# 2. إنشاء Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 3. إنشاء Subnets العامة والخاصة
# Public Subnet A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
    Type = "Public"
  }
}

# Public Subnet B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-b"
    Type = "Public"
  }
}

# Private Subnet A
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-a"
    Type = "Private"
  }
}

# Private Subnet B
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-b"
    Type = "Private"
  }
}

# 4. جدول التوجيه العام (Public Route Table)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. جدول التوجيه الخاص (Private Route Table - بدون مسار إنترنت)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}