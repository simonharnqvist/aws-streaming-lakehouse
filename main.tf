
# Kinesis Data Stream to get data
resource "aws_kinesis_stream" "departures_stream" {
  name = "train-delays-stream"
  shard_count = 1
  retention_period = 24
}

resource "aws_lambda_event_source_mapping" "kinesis_consumer" {
  event_source_arn = aws_kinesis_stream.departures_stream.arn
  function_name = aws_lambda_function.consumer.arn
  starting_position = "LATEST"
  batch_size = 100
  maximum_batching_window_in_seconds = 1
}

### S3 bucket
resource "aws_s3_bucket" "train_streaming" {
  bucket = "train-delays-streaming-simon"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.train_streaming.id 
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.train_streaming.id

  rule{
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.train_streaming.id

  rule {
    id = "expire-old-data"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

resource "aws_iam_policy" "consumer_s3_write" {
  name = "consumer-s3-write"
  description = "Allow consumer Lambda to write to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucket"
      ]
      Resource = [
        "${aws_s3_bucket.train_streaming.arn}",
        "${aws_s3_bucket.train_streaming.arn}/*"
      ]
      }
    ]
  })
}



