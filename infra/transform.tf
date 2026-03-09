resource "aws_lambda_layer_version" "pyarrow" {
    filename = "${path.module}/../layers/layer_pyarrow/layer_pyarrow.zip"
    layer_name = "layer_pyarrow"
    compatible_runtimes = ["python3.12"]
}

resource "aws_lambda_function" "transformer" {
  filename         = "${path.module}/../src/lambdas/transformer/transformer.zip"
  function_name    = "transformer_lambda_function"
  handler          = "transformer.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.transformer.arn
  architectures    = ["x86_64"]
  layers           = [aws_lambda_layer_version.pyarrow.arn]

  source_code_hash = filebase64sha256("${path.module}/../src/lambdas/transformer/transformer.zip")

  timeout     = 30
  memory_size = 512

  environment {
    variables = {
      CLEAN_BUCKET = aws_s3_bucket.clean.bucket
    }
  }
}


resource "aws_s3_bucket_notification" "raw_events" {
    bucket = aws_s3_bucket.raw.id

    lambda_function {
      lambda_function_arn = aws_lambda_function.transformer.arn
      events = ["s3:ObjectCreated:*"]
      filter_prefix = "raw"
      filter_suffix = ".json.gz"
    }

    depends_on = [ aws_lambda_permission.allow_s3_raw ]
}

resource "aws_lambda_permission" "allow_s3_raw" {
    statement_id = "AllowS3Invoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.transformer.function_name
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.raw.arn
}