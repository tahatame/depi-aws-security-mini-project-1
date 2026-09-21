# 1. سياسة كلمة السر الحازمة للحساب
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
}

# 2. إنشاء مجموعة المطورين بصلاحية ReadOnlyAccess
resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

resource "aws_iam_group_policy_attachment" "dev_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 3. إنشاء المستخدم depi-dev-1 وإضافته للمجموعة
resource "aws_iam_user" "dev_user" {
  name = "depi-dev-1"
}

resource "aws_iam_user_group_membership" "dev_user_group" {
  user = aws_iam_user.dev_user.name
  groups = [
    aws_iam_group.developers.name
  ]
}

# 4. سياسة مخصصة لقراءة S3 فقط
resource "aws_iam_policy" "s3_app_read" {
  name        = "${var.project_name}-s3-app-read"
  description = "Allow GetObject on app S3 bucket only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.project_name}-app-*/*"
      }
    ]
  })
}

# 5. إنشاء IAM Role الخاص بسيرفرات EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ربط سياسة Session Manager والسياسة المخصصة بالـ Role
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_app_read.arn
}

# 6. إنشاء Instance Profile لـ EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}