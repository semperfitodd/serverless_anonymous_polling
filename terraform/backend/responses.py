import json

def lambda_handler(event, context):
    # Your code here
    message = "Hello, World!"

    # You can also return a JSON response
    response = {
        "statusCode": 200,
        "body": json.dumps(message)
    }

    return response
