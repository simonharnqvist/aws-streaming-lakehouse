import os
from zeep import Client, Settings, xsd
from zeep.plugins import HistoryPlugin
from zeep.helpers import serialize_object
import boto3
import json
from datetime import datetime, timezone

WSDL = "https://lite.realtime.nationalrail.co.uk/OpenLDBWS/wsdl.aspx?ver=2021-11-01"
CRS = os.getenv("STATION_CODE")
kinesis = boto3.client("kinesis")


def get_departure_board(crs=CRS, num_rows=100):
    LDBWS_TOKEN = os.getenv("ldbws_token")

    settings = Settings(strict=False)
    history = HistoryPlugin()
    client = Client(wsdl=WSDL, settings=settings, plugins=[history])

    header = xsd.Element(
        "{http://thalesgroup.com/RTTI/2013-11-28/Token/types}AccessToken",
        xsd.ComplexType(
            [
                xsd.Element(
                    "{http://thalesgroup.com/RTTI/2013-11-28/Token/types}TokenValue",
                    xsd.String(),
                ),
            ]
        ),
    )
    header_value = header(TokenValue=LDBWS_TOKEN)

    res = client.service.GetDepartureBoard(
        numRows=num_rows, crs=crs, _soapheaders=[header_value]
    )

    return serialize_object(res.trainServices.service)


def lambda_handler(event, context):
    station = os.getenv("STATION_CRS", "EDI")
    raw = get_departure_board()

    enriched = {
        "metadata": {
            "station": station,
            "fetched_at": datetime.now(timezone.utc).isoformat(),
        },
        "payload": raw,
    }

    services = raw.get("trainServices", {}).get("service", [])

    entries = []
    for s in services:
        record = {"metadata": enriched["metadata"], "service": s}
        payload = json.dumps(s).encode("utf-8")
        pk = s.get("serviceID") or s.get("serviceId") or "unknown"
        entries.append({"Data": payload, "PartitionKey": pk})

    response = kinesis.put_records(Records=entries, StreamName="train-delays-stream")

    return {"sent": len(entries), "failed": response["FailedRecordCount"]}
