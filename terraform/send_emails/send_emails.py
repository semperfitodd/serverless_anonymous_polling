import boto3
import json
import os
import time
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Constants
ADMIN_EMAIL = os.environ['ADMIN_EMAIL']
BASE_URL = os.environ['BASE_URL']
DYNAMO_TABLE_NAME = os.environ['DYNAMO_RESPONDENT']
EXCLUDED_EMAILS = set(email.strip() for email in os.environ['EXCLUDED_EMAILS'].split(','))
EXCLUDED_KEYWORDS = set(keyword.strip() for keyword in os.environ['EXCLUDED_KEYWORDS'].split(','))
SCOPES = ['https://www.googleapis.com/auth/admin.directory.user']
SECRET_NAME = os.environ['CREDENTIALS']
TTL_45_DAYS = 45 * 24 * 60 * 60
SENDER = os.environ['SENDER']

# AWS services initialization
secrets_client = boto3.client('secretsmanager')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMO_TABLE_NAME)
ses = boto3.client('ses')

def get_secret():
    """Retrieve the secret from AWS Secrets Manager."""
    return secrets_client.get_secret_value(SecretId=SECRET_NAME)['SecretString']

def contains_excluded_keywords(text):
    """Check if a given text contains any of the excluded keywords."""
    return any(keyword in text.lower() for keyword in EXCLUDED_KEYWORDS)

def write_to_dynamodb(email):
    """Write the email to DynamoDB with TTL."""
    table.put_item(
        Item={
            'respondent_id': email,
            'responded': False,
            'expire': int(time.time()) + TTL_45_DAYS
        }
    )

def send_email_to_user(recipient_email, subject, body_text):
    """Send email using SES."""
    ses.send_email(
        Source=SENDER,
        Destination={'ToAddresses': [recipient_email]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Text': {'Data': body_text}}
        }
    )

def lambda_handler(event, context):
    creds = service_account.Credentials.from_service_account_info(
        json.loads(get_secret()), scopes=SCOPES
    ).with_subject(ADMIN_EMAIL)

    # service = build('admin', 'directory_v1', credentials=creds)
    # users = service.users().list(
    #     customer='my_customer', maxResults=200, orderBy='email'
    # ).execute().get('users', [])

    users = [
        {
            'primaryEmail': 'todd@bernsonfamily.com',
            'name': {'fullName': 'Todd Bernson'}
        },
        {
            'primaryEmail': 'lee@bluesentry.cloud',
            'name': {'fullName': 'Lee Hylton'}
        },
        {
            'primaryEmail': 'brian.dawson@bluesentry.cloud',
            'name': {'fullName': 'Brian Dawson'}
        },
        {
            'primaryEmail': 'sam.reilley@bluesentry.cloud',
            'name': {'fullName': 'Sam Reilley'}
        }
    ]

    for user in users:
        email = user['primaryEmail']
        if (
            email not in EXCLUDED_EMAILS
            and not user.get('suspended', False)
            and not contains_excluded_keywords(email)
            and not contains_excluded_keywords(user['name']['fullName'])
        ):
            first_name = user['name']['fullName'].split()[0]
            message_body = (
                f"{first_name},\n"
                "It's time for the quarterly NPS survey again. We're aiming for 100% participation. "
                "It takes less than 90 seconds to complete the two-question survey. "
                f"Thanks for taking this anonymous survey!\n{BASE_URL}?email={email}\n\n"
            )
            send_email_to_user(email, "Quarterly NPS Survey", message_body)
            write_to_dynamodb(email)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Emails sent successfully.'
        }),
        'headers': {
            'Content-Type': 'application/json'
        }
    }
