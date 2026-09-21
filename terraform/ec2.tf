# 1. جلب أحدث صورة لـ Amazon Linux 2023 تلقائياً
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. السيرفر الأول في Private Subnet A
resource "aws_instance" "app_server_a" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from DEPI Web Server - AZ: us-east-1a</h1>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-app-server-a"
  }
}

# 3. السيرفر الثاني في Private Subnet B
resource "aws_instance" "app_server_b" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_b.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello from DEPI Web Server - AZ: us-east-1b</h1>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "${var.project_name}-app-server-b"
  }
}