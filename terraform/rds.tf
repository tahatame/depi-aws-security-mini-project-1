# 1. DB Subnet Group لربط قاعدة البيانات بالـ Private Subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 2. إنشاء قاعدة بيانات MySQL مشفرة وفي Private Subnet
resource "aws_db_instance" "app_db" {
  identifier             = "${var.project_name}-db"
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "depidb"
  username               = "admin"
  password               = "DEPIpassword123!"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true

  tags = {
    Name = "${var.project_name}-db"
  }
}