resource "aws_athena_database" "athena_delays" {
  name   = "athena_delays"
  bucket = "${aws_s3_bucket.clean.bucket}/athena-results/"
}

resource "aws_athena_workgroup" "delays" {
  name = "delays"
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.clean.bucket}/athena-results/"
    }
  }

  state = "ENABLED"
}

