# 1. إنشاء نظام الملفات المشفر EFS
resource "aws_efs_file_system" "shared_efs" {
  creation_token = "${var.project_name}-shared-efs"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-shared-efs"
  }
}

# 2. إنشاء Mount Targets في الـ Private Subnets
resource "aws_efs_mount_target" "target_a" {
  file_system_id  = aws_efs_file_system.shared_efs.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "target_b" {
  file_system_id  = aws_efs_file_system.shared_efs.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs_sg.id]
}

# 3. إنشاء EFS Access Point
resource "aws_efs_access_point" "app_ap" {
  file_system_id = aws_efs_file_system.shared_efs.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/app-data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "${var.project_name}-efs-access-point"
  }
}
# 4. S3 Bucket لتخزين ملفات التطبيق بأمان
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = "${var.project_name}-app-data-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-app-data"
  }
}

# حظر الوصول العام بالكامل (Block Public Access)
resource "aws_s3_bucket_public_access_block" "app_bucket_pab" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# تفعيل التشفير المباشر (Server-Side Encryption)
resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket_encryption" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# تفعيل الإصدارات (Versioning)
resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}