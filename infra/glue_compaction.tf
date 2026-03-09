resource "aws_s3_bucket" "scripts_bucket" {
  bucket        = var.glue_scripts_bucket
  force_destroy = true

  tags = {
    Name = "glue-scripts"
  }
}

resource "aws_s3_bucket_versioning" "scripts_bucket_versioning" {
  bucket = aws_s3_bucket.scripts_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts_bucket_sse" {
  bucket = aws_s3_bucket.scripts_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scripts_bucket_block" {
  bucket = aws_s3_bucket.scripts_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "glue_compaction_script" {
  bucket = var.glue_scripts_bucket
  key    = "glue/glue_compaction.py"

  source = "${path.module}/../src/glue/glue_compaction.py"
  etag   = filemd5("${path.module}/../src/glue/glue_compaction.py")
}

resource "aws_glue_job" "compaction" {
  name     = "cleaned-compaction-job"
  role_arn = aws_iam_role.glue_compaction_role.arn

  command {
    name            = "glue-compaction"
    script_location = "s3://${var.glue_scripts_bucket}/${aws_s3_object.glue_compaction_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"  = "python"
    "--SILVER-PREFIX" = "s3://train-delays-clean-simon/clean/"
    "--TARGET-DATE"   = "2026-03-04"
    "--enable-metrics" = "true"
  }

  glue_version       = "4.0"
  number_of_workers  = 2
  worker_type        = "G.1X"
}

resource "aws_glue_trigger" "compaction_hourly" {
  name     = "compaction-hourly"
  type     = "SCHEDULED"
  schedule = "cron(0 * * * ? *)"

  actions {
    job_name = aws_glue_job.compaction.name

    arguments = {
      "--TARGET_DATE" = formatdate("YYYY-MM-DD", timestamp())
      "--STATION"     = "EDB"
    }
  }
}
