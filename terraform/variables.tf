variable "project_name" {
  type    = string
  default = "depi-sec"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "alert_email" {
  type        = string
  default     = "tahatamer93@gmail.com" # ضع إيميلك الشخصي هنا
  description = "Your email address for notifications"
}