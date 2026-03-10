import boto3
import re
import os

glue = boto3.client("glue")

DATABASE = os.getenv("GLUE_DATABASE")
TABLE = os.getenv("GLUE_TABLE")

# Example key:
# clean/date=2025-03-10/station=EDB/part-1234.parquet
PARTITION_REGEX = re.compile(r"date=(?P<date>[^/]+)/station=(?P<station>[^/]+)/")


def lambda_handler(event, context):
    record = event["Records"][0]
    key = record["s3"]["object"]["key"]

    match = PARTITION_REGEX.search(key)
    if not match:
        print(f"No partition info found in key: {key}")
        return

    date = match.group("date")
    station = match.group("station")

    partition_values = [date, station]
    s3_path = f"s3://{record['s3']['bucket']['name']}/{os.path.dirname(key)}/"

    try:
        glue.batch_create_partition(
            DatabaseName=DATABASE,
            TableName=TABLE,
            PartitionInputList=[
                {"Values": partition_values, "StorageDescriptor": {"Location": s3_path}}
            ],
        )
        print(f"Created partition: date={date}, station={station}")
    except glue.exceptions.AlreadyExistsException:
        print(f"Partition already exists: {partition_values}")
    except Exception as e:
        print(f"Error creating partition: {e}")
        raise
