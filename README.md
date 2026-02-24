# aws-streaming-lakehouse
AWS Streaming + Lakehousing project

## Architecture
ETL streaming -> lakehouse project, with Terraform for IaC and CloudWatch for monitoring.

Extract & load: λ Lambda producer polling API -> Kinesis Data Stream ≋ -> λ Lambda consumer -> S3 bucket 🪣
Transformation: Glue? LakeFormation?
Serve: Athena + QuickSight

## How to use

Set LDBWS token (obtain from website) in .env:
```shell
LDBWS_TOKEN="abc123"
```

Build layers and lambda functions:
```shell
./build.sh
```
The build is automatically validated and should throw human-readable errors if artifacts are missing.

Deploy with Terraform:
```shell
./deploy.sh
```
