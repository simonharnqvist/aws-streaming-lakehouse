# aws-streaming-lakehouse
AWS Streaming + Lakehousing project

## Outline
ETL streaming -> lakehouse project, with Terraform for IaC and CloudWatch for monitoring.

### Extract
* Poll data from National Rail API using a Lambda function (boto3 + requests) with Kinesis Data Streams

### Transform
* Lambda on-the-fly transformation - strip out some relevant info

### Load
* Send to S3
* Glue Data Catalog

### Serve
* Athena for queries
* QuickSight dashboard, e.g. current avg delay
