import json

def lambda_handler(event, context):
    print("READY FOR RDS WRITE:")
    print(json.dumps(event))
    return {"statusCode": 200}
    import json
import psycopg2
import boto3

secrets = boto3.client('secretsmanager')

def get_db_credentials():
    response = secrets.get_secret_value(
        SecretId="hellotags-db-credentials-v1"
    )
    return json.loads(response['SecretString'])

def lambda_handler(event, context):
    try:
        detail = event.get("detail", {})
        card_id = detail.get("card_id")
        timestamp = detail.get("timestamp")

        creds = get_db_credentials()

        conn = psycopg2.connect(
            host=creds["host"],
            database=creds["dbname"],
            user=creds["username"],
            password=creds["password"],
            port=5432
        )

        cursor = conn.cursor()

        cursor.execute(
            "INSERT INTO tap_analytics (card_id, timestamp) VALUES (%s, %s)",
            (card_id, timestamp)
        )

        conn.commit()
        cursor.close()
        conn.close()

        print("INSERT SUCCESS")

        return {"statusCode": 200}

    except Exception as e:
        print("ERROR:", str(e))
        return {"statusCode": 500}
