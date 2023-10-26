import boto3
import json
import os
from botocore.exceptions import ClientError

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
}

dynamodb = boto3.resource('dynamodb')
respondent_table = dynamodb.Table(os.environ['DYNAMO_RESPONDENT'])
responses_table = dynamodb.Table(os.environ['DYNAMO_RESPONSES'])


def lambda_handler(event, context):
    try:
        # 1. Lists of Respondents
        scan_respondents = respondent_table.scan()
        respondents_responded = [item['respondent_id'] for item in scan_respondents['Items'] if
                                 item['responded'] == True]
        respondents_not_responded = [item['respondent_id'] for item in scan_respondents['Items'] if
                                     item['responded'] == False]

        # 2. Completion Percentage
        total_respondents = len(scan_respondents['Items'])
        total_responded = len(respondents_responded)
        completion_percentage = (total_responded / total_respondents) * 100

        # 3. Totals for each number in responses
        scan_responses = responses_table.scan()
        score_counts = {i: 0 for i in range(1, 11)}  # Initializing a dictionary to store counts of scores from 1 to 10

        for response in scan_responses['Items']:
            score = response['score']
            if 1 <= score <= 10:
                score_counts[score] += 1

        return {
            'statusCode': 200,
            'body': json.dumps({
                'respondents_responded': respondents_responded,
                'respondents_not_responded': respondents_not_responded,
                'completion_percentage': completion_percentage,
                'score_counts': score_counts
            }),
            'headers': CORS_HEADERS
        }
    except ClientError as e:
        # logging the exact error message can be added here for further debugging
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error retrieving results.', 'error': str(e)}),
            'headers': CORS_HEADERS
        }
