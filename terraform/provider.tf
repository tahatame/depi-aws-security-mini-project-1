provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "depi-mini-project-1"
      Owner       = "Taha"
      Environment = "lab"
      ManagedBy   = "terraform"
    }
  }
}