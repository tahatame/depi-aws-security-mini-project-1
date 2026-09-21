# 1. Security Group للـ Load Balancer (مفتوح للعامة على بورت 80)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow public HTTP traffic to ALB"
  vpc_id      = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 2. Security Group لسيرفرات التطبيق (يقبل فقط من الـ ALB SG)
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Allow HTTP traffic from ALB SG only"
  vpc_id      = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "app_egress_all" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 3. Security Group لقاعدة البيانات RDS (يقبل فقط من الـ App SG على بورت 3306)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow MySQL traffic from App SG only"
  vpc_id      = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

# 4. Security Group لنظام الملفات EFS (يقبل فقط من الـ App SG على بورت 2049)
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow NFS traffic from App SG only"
  vpc_id      = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-efs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_app" {
  security_group_id            = aws_security_group.efs_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}
# 5. Network ACL مخصص للـ Private Subnets
resource "aws_network_acl" "private_nacl" {
  vpc_id     = aws_vpc.app_vpc.id
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Inbound 100: السماح بحركة HTTP (80) من داخل VPC
  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 80
    to_port    = 80
    protocol   = "tcp"
  }

  # Inbound 110: السماح بحركة HTTPS (443) من داخل VPC
  ingress {
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
    protocol   = "tcp"
  }

  # Inbound 120: السماح بـ Ephemeral Ports لحركة العودة من داخل VPC
  ingress {
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
    protocol   = "tcp"
  }

  # Inbound 200: حظر صريح لبورت SSH (22) من أي مكان
  ingress {
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
    protocol   = "tcp"
  }

  # Outbound 100: السماح بكل حركة الخروج إلى داخل VPC
  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  # Outbound 110: السماح بـ HTTPS للخروج للإنترنت (مهم للـ VPC Endpoints لاحقاً)
  egress {
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
    protocol   = "tcp"
  }

  tags = {
    Name = "${var.project_name}-private-nacl"
  }
}