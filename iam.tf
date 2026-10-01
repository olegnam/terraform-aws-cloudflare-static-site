data "aws_caller_identity" "current" {}

locals {
  bucket_name = var.site_bucket_name != "" ? var.site_bucket_name : "${replace(var.project_name, "-", "")}-site-content-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Name = "${var.project_name}-site-content"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}
