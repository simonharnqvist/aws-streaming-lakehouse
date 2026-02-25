### RAW BUCKET ###
resource "aws_s3_bucket" "raw" {
    bucket = "train-delays-raw-simon"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "raw_versioning" {
    bucket = aws_s3_bucket.raw.id

    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_sse" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_block" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### CLEAN BUCKET ###
resource "aws_s3_bucket" "clean" {
    bucket = "train-delays-clean-simon"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "clean_versioning" {
    bucket = aws_s3_bucket.clean.id

    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clean_sse" {
  bucket = aws_s3_bucket.clean.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "_block" {
  bucket = aws_s3_bucket.clean.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}