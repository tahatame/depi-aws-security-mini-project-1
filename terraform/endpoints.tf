# 1. S3 Gateway Endpoint (مجاني ويُضاف لجدول التوجيه الخاص)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = {
    Name = "${var.project_name}-s3-gw-endpoint"
  }
}

# 2. Security Group مخصص لـ Interface Endpoints (يقبل 443 من داخل VPC)
resource "aws_security_group" "endpoint_sg" {
  name        = "${var.project_name}-endpoint-sg"
  description = "Allow HTTPS inbound from VPC to endpoints"
  vpc_id      = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-endpoint-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_https" {
  security_group_id = aws_security_group.endpoint_sg.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# 3. SSM Interface Endpoints (3 endpoints لخدمة Systems Manager)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ec2messages-endpoint"
  }
}