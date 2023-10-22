import json
import boto3
import os
import hashlib
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Table references from environment variables
respondent_table = dynamodb.Table(os.environ['DYNAMO_RESPONDENT'])
responses_table = dynamodb.Table(os.environ['DYNAMO_RESPONSES'])

def generate_response_id(email):
    return hashlib.sha256(email.encode()).hexdigest()

def lambda_handler(event, context):
    cors_headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
    }

    # Extracting the email from the query string parameters
    respondent_id = event['queryStringParameters']['email']

    # Extracting the body from the API Gateway event
    body = json.loads(event['body'])

    score = body['score']
    feedback = body['feedback']

    # Ensure the score is between 1 and 10
    if not (1 <= score <= 10):
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Score should be between 1 and 10.'}),
            'headers': cors_headers
        }

    try:
        # Mark the respondent as having completed the survey
        respondent_table.put_item(
            Item={
                'respondent_id': respondent_id,
                'responded': True
            }
        )

        # Add the anonymous response to the responses table
        responses_table.put_item(
            Item={
                'response_id': generate_response_id(respondent_id),
                'score': score,
                'feedback': feedback
            }
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Response recorded successfully.'}),
            'headers': cors_headers
        }

    except ClientError as e:
        print(e.response['Error']['Message'])
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error recording response.'}),
            'headers': cors_headers
        }
