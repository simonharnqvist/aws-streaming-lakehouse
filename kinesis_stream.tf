resource "aws_kinesis_stream" "kinesis_stream" {
  name = "kinesis_stream"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  retention_period = 24

  tags = {
    Environment = "dev"
  }
}
