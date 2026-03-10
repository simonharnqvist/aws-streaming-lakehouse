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
