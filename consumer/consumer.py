import boto3
import os
import base64
import json
from datetime import datetime, timezone
import gzip

s3 = boto3.client("s3")
BUCKET = os.environ["RAW_BUCKET"]


def lambda_handler(event, context):
    processed = [
        json.loads(base64.b64decode(record["kinesis"]["data"]))
        for record in event["Records"]
    ]

    if not processed:
        return {"written": 0}

    now = datetime.now(tz=timezone.utc)
    prefix = f"raw/year={now.year}/month={now.month:02d}/day={now.day:02d}"

    body = "\n".join(json.dumps(x) for x in processed).encode("utf-8")

    s3.put_object(
        Bucket=BUCKET,
        Key=f"{prefix}/batch-{now.timestamp()}.json.gz",
        Body=gzip.compress(body),
        ContentType="application/json",
        ContentEncoding="gzip",
    )

    return {"written": len(processed)}
