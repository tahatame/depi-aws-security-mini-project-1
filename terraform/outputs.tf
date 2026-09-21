output "alb_dns_name" {
  description = "رابط DNS الخاص بموزّع الأحمال ALB"
  value       = aws_lb.app_alb.dns_name
}

output "cloudfront_domain_name" {
  description = "رابط CloudFront CDN الخاص بالموقع"
  value       = aws_cloudfront_distribution.alb_cdn.domain_name
}

output "s3_bucket_name" {
  description = "اسم حاوية S3 المشفرة"
  value       = aws_s3_bucket.app_bucket.id
}

output "rds_endpoint" {
  description = "عنوان الاتصال بقاعدة البيانات RDS"
  value       = aws_db_instance.app_db.endpoint
}