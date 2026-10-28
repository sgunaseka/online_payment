# Concierto Change Studio - first AWS test.
# Creates one private, versioned S3 bucket. Needs only S3 permissions (the "studio" role has s3:*).
# Credentials and region come from the stack's AWS cloud integration; nothing secret is stored here.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # No backend block on purpose: Concierto keeps the state for this stack.
}

variable "region" {
  type        = string
  description = "AWS region. The run also sets AWS_REGION from the cloud integration."
  default     = "ca-central-1"
}

variable "name_prefix" {
  type    = string
  default = "concierto-test"
}
variable "env" {
  type    = string
  default = "unset"
}
provider "aws" {
  region = var.region
}

# Bucket names are global, so add a random suffix.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "test" {
  bucket        = "${var.name_prefix}-${random_id.suffix.hex}"
  force_destroy = true # lets a later "remove it from main.tf and apply" delete a bucket that has objects

  tags = {
    ManagedBy = "concierto-change-studio"
    Purpose   = "run-engine-test"
    Environment = var.env
  }
}

resource "aws_s3_bucket_versioning" "test" {
  bucket = aws_s3_bucket.test.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket                  = aws_s3_bucket.test.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_name" {
  value = aws_s3_bucket.test.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.test.arn
}

output "region" {
  value = var.region
}
