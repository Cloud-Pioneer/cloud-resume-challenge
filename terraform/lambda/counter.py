import json
import boto3
import os

# Connect to DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    # Add 1 to the visitor count (creates the record if it doesn't exist yet)
    response = table.update_item(
        Key={'id': 'visitor_count'},
        UpdateExpression='ADD visit_count :inc',
        ExpressionAttributeValues={':inc': 1},
        ReturnValues='UPDATED_NEW'
    )

    count = int(response['Attributes']['visit_count'])

    # Return the count — the website reads this and displays it
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            # This allows your website to call this API from the browser
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'visitor_count': count})
    }