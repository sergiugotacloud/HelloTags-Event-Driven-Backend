import json

def lambda_handler(event, context):
    print("EVENT RECEIVED:")
    print(json.dumps(event))

    return {
        "statusCode": 200,
        "body": json.dumps("notification processed")
    }
