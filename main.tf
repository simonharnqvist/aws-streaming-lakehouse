
# Lambda function to get departure board info
resource "aws_lambda_function" "fetcher" {
  function_name = "rail-fetcher"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "fetcher.zip"
  source_code_hash = filebase64sha256("fetcher.zip")

  environment {
    variables = {
      QUEUE_URL    = aws_sqs_queue.rail_queue.url
      ldbws_token  = var.ldbws_token
    }
  }
}


resource "aws_iam_role_policy" "fetcher_sqs" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sqs:SendMessage"
      Resource = aws_sqs_queue.rail_queue.arn
    }]
  })
}

# Transformer Lambda function
resource "aws_lambda_function" "transformer" {
  function_name = "rail-transformer"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "transformer.zip"
  source_code_hash = filebase64sha256("transformer.zip")
}

resource "aws_iam_role_policy" "transformer_sqs" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = aws_sqs_queue.rail_queue.arn
    }]
  })
}

# SQS queue between fetcher and transformer
resource "aws_lambda_event_source_mapping" "sqs_to_transformer" {
  event_source_arn  = aws_sqs_queue.rail_queue.arn
  function_name     = aws_lambda_function.transformer.arn
  batch_size        = 10
}



# EventBridge cron job
resource "aws_scheduler_schedule" "api_poll_trigger" {
  name = "api-trigger-schedule"
  group_name = "default"

  # run on schedule, not flexible
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minute)"

  target {
    arn = aws_lambda_function.nr_poller.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda.arn
  }
}


