import os
from zeep import Client, Settings, xsd
from zeep.plugins import HistoryPlugin
from zeep.helpers import serialize_object
import boto3
import json

WSDL = 'https://lite.realtime.nationalrail.co.uk/OpenLDBWS/wsdl.aspx?ver=2021-11-01'
sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]

def get_departure_board(crs="EDB", num_rows=100):
    LDB_TOKEN = os.getenv("ldbws_token")

    settings = Settings(strict=False)
    history = HistoryPlugin()
    client = Client(wsdl=WSDL, settings=settings, plugins=[history])

    header = xsd.Element(
        '{http://thalesgroup.com/RTTI/2013-11-28/Token/types}AccessToken',
        xsd.ComplexType([
            xsd.Element(
                '{http://thalesgroup.com/RTTI/2013-11-28/Token/types}TokenValue',
                xsd.String()),
        ])
    )
    header_value = header(TokenValue=LDB_TOKEN)

    res = client.service.GetDepartureBoard(
        numRows=num_rows,
        crs=crs,
        _soapheaders=[header_value]
    )

    return serialize_object(res.trainServices.service)

def lambda_handler(event, context):
    data = get_departure_board()
    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(data)
    )
