import boto3
import json
from datetime import datetime
import pyarrow as pa
import pyarrow.parquet as pq
import io
import os

s3 = boto3.client("s3")
CLEAN_BUCKET = os.getenv("CLEAN_BUCKET")


def departure_info(departures: list) -> list[dict]:
    formatted = []

    for dep in departures:
        formatted.append(
            {
                "serviceID": dep.get("serviceID"),
                "scheduled": dep.get("std"),
                "estimated": dep.get("etd"),
                "delay": delay(dep.get("std"), dep.get("etd")),
                "origin": dep["origin"]["location"][0]["locationName"],
                "destination": dep["destination"]["location"][0]["locationName"],
            }
        )

    return formatted


def delay(scheduled: str, estimated: str) -> int | None:

    if not scheduled or not estimated:
        return None

    if estimated == "On time":
        return 0

    # Handle "Cancelled", "Delayed", "No report", etc.
    if not _is_hhmm(estimated):
        return None

    sched_time = datetime.strptime(scheduled, "%H:%M")
    estd_time = datetime.strptime(estimated, "%H:%M")

    diff = (estd_time - sched_time).total_seconds() / 60
    delay_minutes = round(diff)

    # Midnight rollover (e.g., 23:55 → 00:10)
    if delay_minutes < 0:
        delay_minutes += 24 * 60

    return delay_minutes


def _is_hhmm(value: str) -> bool:
    """Return True if value looks like HH:MM."""
    try:
        datetime.strptime(value, "%H:%M")
        return True
    except Exception:
        return False


def handler(event, context):
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]

    raw_bytes = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
    raw_lines = raw_bytes.decode("utf-8").splitlines()

    records = [json.loads(line) for line in raw_lines]

    if not records:
        print("No records found in raw file")
        return {"status": "empty"}

    metadata = records[0]["metadata"]
    station = metadata["station"]
    date = metadata["fetched_at"][:10]  # surely nicer to get date with a method

    clean_rows = []
    for record in records:
        service = record["service"]
        clean_rows.extend(departure_info([service]))

    if not clean_rows:
        print("No clean rows produced")
        return {"status": "no_clean"}

    table = pa.from_pylist(clean_rows)
    buf = io.BytesIO()
    pq.write_table(table, buf)
    parquet_bytes = buf.getvalue()

    clean_key = (
        f"clean/date={date}/station={station}/part-{context.aws_request_id}.parquet"
    )

    s3.put_object(
        Bucket=CLEAN_BUCKET,
        Key=clean_key,
        Body=parquet_bytes,
        ContentType="application/octet-stream",
    )

    print(f"Wrote clean parquet: s3://{CLEAN_BUCKET}/{clean_key}")
    return {"status": "ok", "records": len(clean_rows)}
