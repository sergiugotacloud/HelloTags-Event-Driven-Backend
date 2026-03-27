import json
import time
import os
import boto3

dynamodb = boto3.resource('dynamodb')
events = boto3.client('events')

table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        card_id = body.get('card_id')

        if not card_id:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "card_id is required"})
            }

        timestamp = int(time.time() * 1000)

        table.put_item(
            Item={
                "card_id": card_id,
                "timestamp": timestamp
            }
        )

        events.put_events(
            Entries=[
                {
                    "Source": "hellotags.tap",
                    "DetailType": "TapEvent",
                    "Detail": json.dumps({
                        "card_id": card_id,
                        "timestamp": timestamp
                    })
                }
            ]
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "tap recorded"
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
