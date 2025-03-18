import json
import boto3
import gzip
import psycopg2
import os
import urllib.parse
from io import BytesIO

# Initialize AWS clients
# s3_client = boto3.client('s3')
# secrets_client = boto3.client('secretsmanager')
AWS_REGION = "us-west-1"
s3_client = boto3.client('s3', region_name=AWS_REGION)
secrets_client = boto3.client('secretsmanager', region_name=AWS_REGION)

# Fetch credentials from AWS Secrets Manager
def get_redshift_credentials():
    secret_name = "bg-redshift-credentials"
    region_name = "us-west-1"

    try:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        secret = json.loads(response["SecretString"])
        return secret
    except secrets_client.exceptions.ResourceNotFoundException:
        print(f"Secret {secret_name} not found")
    except secrets_client.exceptions.AccessDeniedException:
        print(f"Access denied to {secret_name}")
    except Exception as e:
        print(f"Error retrieving secret: {str(e)}")

    return None  # Return None to indicate failure

def lambda_handler(event, context):
    creds = get_redshift_credentials()
    if not creds:
        return {"statusCode": 500, "body": "Failed to retrieve Redshift credentials"}

    redshift_host = creds["REDSHIFT_HOST"]
    redshift_db = creds["REDSHIFT_DBNAME"]
    redshift_user = creds["REDSHIFT_USER"]
    redshift_password = creds["REDSHIFT_PASSWORD"]
    redshift_table = "security_logs"

    # Ensure table exists before inserting data
    create_redshift_table(redshift_host, redshift_db, redshift_user, redshift_password, redshift_table)

    try:
        if "Records" not in event or not event["Records"]:
            print("Error: No 'Records' key in event")
            return {"statusCode": 400, "body": "No 'Records' key in event"}

        record = event["Records"][0]
        bucket_name = record["s3"]["bucket"]["name"]
        object_key = urllib.parse.unquote(record["s3"]["object"]["key"])  

        print(f"Processing file: s3://{bucket_name}/{object_key}")

        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        gzipped_content = response['Body'].read()

        with gzip.GzipFile(fileobj=BytesIO(gzipped_content), mode='rb') as f:
            file_content = f.read().decode("utf-8")

        print(f"Raw file content: {file_content[:500]}")

        try:
            log_data = json.loads(file_content)
        except json.JSONDecodeError as e:
            print(f"JSON Parsing Error: {str(e)}")
            return {"statusCode": 500, "body": "Invalid JSON format in log file"}

        if not log_data or "Records" not in log_data:
            print("Error: No 'Records' key in parsed log data")
            return {"statusCode": 400, "body": "No 'Records' key in parsed log data"}

        print(f"Extracted JSON Data: {json.dumps(log_data, indent=2)}")

        insert_to_redshift(log_data, redshift_host, redshift_db, redshift_user, redshift_password, redshift_table)

        return {
            "statusCode": 200,
            "body": "Data successfully processed and inserted into Redshift"
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": str(e)
        }

def create_redshift_table(host, dbname, user, password, table):
    """ Creates the Redshift table if it does not exist """
    try:
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=5439,
            connect_timeout=10  
        )
        cursor = conn.cursor()

        # Check if table exists
        cursor.execute(f"SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = '{table}';")
        result = cursor.fetchone()

        if not result:
            print(f"Table '{table}' does not exist. Creating now...")
            create_table_query = f"""
                CREATE TABLE {table} (
                    event_time TIMESTAMP,
                    event_name VARCHAR(256),
                    user_identity VARCHAR(5000),
                    source_ip VARCHAR(256),
                    request_params VARCHAR(5000)
                );
            """
            cursor.execute(create_table_query)
            conn.commit()
            print(f"Table '{table}' created successfully.")
        else:
            print(f"Table '{table}' already exists.")

        cursor.close()
        conn.close()
    
    except Exception as e:
        print(f"Error creating Redshift table: {str(e)}")

def insert_to_redshift(log_data, host, dbname, user, password, table):
    try:
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=5439,
            connect_timeout=10  
        )
        cursor = conn.cursor()

        print(f"Full Log Data: {json.dumps(log_data, indent=2)}")

        if "Records" not in log_data:
            print("Error: 'Records' key missing in log_data")
            return

        for record in log_data.get("Records", []):
            event_time = record.get("eventTime", None)
            event_name = record.get("eventName", None)
            user_identity = json.dumps(record.get("userIdentity", {})) if record.get("userIdentity") else None
            source_ip = record.get("sourceIPAddress", None)
            request_params = json.dumps(record.get("requestParameters", {})) if record.get("requestParameters") else None

            query = f"""
                INSERT INTO {table} (event_time, event_name, user_identity, source_ip, request_params)
                VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(query, (event_time, event_name, user_identity, source_ip, request_params))

        conn.commit()
        cursor.close()
        conn.close()
        print("Data successfully inserted into Redshift")

    except Exception as e:
        print(f"Redshift Insert Error: {str(e)}")