# train-delays-streaming-aws
AWS personal project to practise streaming/microbatching and Terraform.

This pipeline polls the live departure board at Waverley Station (Edinburgh) and ultimately gets the current average delay for dashboard use. 

Stack:
* AWS Lambda - fetcher, consumer, and transformation functions
* Kinesis Data Streams - for streaming data from polling function to consumer
* S3 - data storage/lakehouse
* Glue - hourly compaction of parquets to avoid small files problem
* Athena - data lakehouse (in progress)
* QuickSight dashboard?

## How to use

Set LDBWS token (obtain from website) in .env:
```shell
LDBWS_TOKEN="abc123"
```

Build layers and lambda functions:
```shell
make build
```
The build is automatically validated and should throw human-readable errors if artifacts are missing.

Deploy with Terraform:
```shell
make deploy
```

Once done, destroy all resources with:
```shell
make destroy
```
