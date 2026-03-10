resource "aws_glue_catalog_database" "glue_catalog" {
  name = "train_delays_catalog"
}

resource "aws_glue_catalog_table" "train_delays" {
  name          = "train_delays"
  database_name = aws_glue_catalog_database.glue_catalog.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "parquet"
    EXTERNAL       = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.clean.bucket}/clean/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "serviceid"
      type = "string"
    }

    columns {
      name = "scheduled"
      type = "string"
    }

    columns {
      name = "estimated"
      type = "string"
    }

    columns {
      name = "delay"
      type = "int"
    }

    columns {
      name = "origin"
      type = "string"
    }

    columns {
      name = "destination"
      type = "string"
    }
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  partition_keys {
    name = "station"
    type = "string"
  }
}

resource "aws_lambda_function" "update_partitions" {
  filename         = "${path.module}/../src/lambdas/update_partitions/update_partitions.zip"
  function_name    = "update_partitions"
  role             = aws_iam_role.update_partitions_role.arn
  handler          = "update_partitions.lambda_handler"
  runtime          = "python3.12"

  environment {
    variables = {
      GLUE_DATABASE = aws_glue_catalog_database.glue_catalog.name
      GLUE_TABLE    = aws_glue_catalog_table.train_delays.name
    }
  }
}

resource "aws_lambda_permission" "allow_clean_bucket" {
  statement_id  = "AllowExecutionFromCleanBucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_partitions.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.clean.arn
}

resource "aws_s3_bucket_notification" "clean_bucket_notification" {
  bucket = aws_s3_bucket.clean.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.update_partitions.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "clean/"
    filter_suffix       = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_clean_bucket]
}
