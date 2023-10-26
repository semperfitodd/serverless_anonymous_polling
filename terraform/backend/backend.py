import boto3
import hashlib
import json
import os
import time
from botocore.exceptions import ClientError

TTL_30_DAYS = 30 * 24 * 60 * 60
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
}

dynamodb = boto3.resource('dynamodb')
respondent_table = dynamodb.Table(os.environ['DYNAMO_RESPONDENT'])
responses_table = dynamodb.Table(os.environ['DYNAMO_RESPONSES'])

def generate_response_id(email):
    """Generate a unique ID based on the email."""
    return hashlib.sha256(email.encode()).hexdigest()

def get_ttl_expire_time():
    """Return the epoch time for 30 days from now."""
    return int(time.time()) + TTL_30_DAYS

def lambda_handler(event, context):
    # Extract data from the event
    respondent_id = event['queryStringParameters']['email']
    body = event.get('body')
    if not body:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'No body found in the request.'}),
            'headers': CORS_HEADERS
        }

    data = json.loads(body)
    score = data.get('score')
    feedback = data.get('feedback')

    if not (1 <= score <= 10):
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Score should be between 1 and 10.'}),
            'headers': CORS_HEADERS
        }

    try:
        respondent_table.put_item(
            Item={
                'respondent_id': respondent_id,
                'responded': True,
                'expire': get_ttl_expire_time()
            }
        )

        responses_table.put_item(
            Item={
                'response_id': generate_response_id(respondent_id),
                'score': score,
                'feedback': feedback,
                'expire': get_ttl_expire_time()
            }
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Response recorded successfully.'}),
            'headers': CORS_HEADERS
        }

    except ClientError:
        # logging the exact error message can be added here for further debugging
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error recording response.'}),
            'headers': CORS_HEADERS
        }
