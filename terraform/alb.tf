# 1. إنشاء Application Load Balancer في الـ Public Subnets
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# 2. إنشاء Target Group مع إعدادات فحص السلامة (Health Check)
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# 3. ربط السيرفرين بالـ Target Group
resource "aws_lb_target_group_attachment" "attach_a" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_b" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_b.id
  port             = 80
}

# 4. إنشاء Listener لتوجيه الطلبات القادمة على بورت 80 إلى الـ Target Group
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}