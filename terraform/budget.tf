# 1. إنشاء IAM Policy لمنع إنشاء سيرفرات أو قواعد بيانات مكلفة عند تجاوز الميزانية
resource "aws_iam_policy" "deny_expensive" {
  name        = "${var.project_name}-deny-expensive"
  description = "Deny launching EC2 instances and RDS DB instances when budget is exceeded"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyExpensiveResources"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. إنشاء IAM Role لخدمة AWS Budgets لتقوم بالصلاحية عند الحاجة
resource "aws_iam_role" "budget_action_role" {
  name = "${var.project_name}-budget-action-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ربط السياسة بالـ Role
resource "aws_iam_role_policy_attachment" "budget_action_attach" {
  role       = aws_iam_role.budget_action_role.name
  policy_arn = aws_iam_policy.deny_expensive.arn
}

# 3. إنشاء الميزانية الشهرية (Monthly Budget) بقيمة $10 مع الإشعارات
resource "aws_budgets_budget" "monthly_budget" {
  name              = "${var.project_name}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  # إشعار 1: إيميل عند الوصول لـ 80% من التكلفة الفعلية
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # إشعار 2: إيميل عند توقع الوصول لـ 100% من التكلفة نهاية الشهر
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}