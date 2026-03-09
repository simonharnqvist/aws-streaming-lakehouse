resource "aws_lambda_layer_version" "python_deps" {
    filename = "${path.module}/../layers/layer_python/layer_python.zip"
    layer_name = "layer_python"
    compatible_runtimes = ["python3.12"]
}

resource "aws_lambda_function" "fetcher" {
  filename         = "${path.module}/../src/lambdas/fetcher/fetcher.zip"
  function_name    = "fetcher_lambda_function"
  handler          = "fetcher.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.fetcher.arn
  architectures    = ["x86_64"]
  layers           = [aws_lambda_layer_version.python_deps.arn]

  source_code_hash = filebase64sha256("${path.module}/../src/lambdas/fetcher/fetcher.zip")

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      LDBWS_TOKEN = var.ldbws_token
      STATION_CRS = var.station_crs
      STREAM_NAME = aws_kinesis_stream.departures_stream.name
    }
  }
}


resource "aws_cloudwatch_event_rule" "fetcher_schedule" {
    name = "fetcher_every_60s"
    schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "fetcher_target" {
    rule = aws_cloudwatch_event_rule.fetcher_schedule.name
    target_id = "fetcher_lambda"
    arn = aws_lambda_function.fetcher.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.fetcher_schedule.arn
}

resource "aws_kinesis_stream" "departures_stream" {
    name = "train-delays-stream"
    shard_count = 1
    retention_period = 24
}

resource "aws_lambda_function" "consumer" {
  function_name = "train_consumer_lambda"

  filename         = "${path.module}/../src/lambdas/consumer/consumer.zip"
  source_code_hash = filebase64sha256("${path.module}/../src/lambdas/consumer/consumer.zip")

  handler = "consumer.lambda_handler"
  runtime = "python3.12"
  role    = aws_iam_role.consumer.arn

  architectures = ["x86_64"]

  timeout     = 60
  memory_size = 512

  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
    }
  }
}


resource "aws_lambda_event_source_mapping" "kinesis_consumer" {
    event_source_arn = aws_kinesis_stream.departures_stream.arn
    function_name = aws_lambda_function.consumer.arn
    starting_position = "LATEST"
    batch_size = 100
    maximum_batching_window_in_seconds = 1
}