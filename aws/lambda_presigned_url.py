import json
import boto3
import os
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    try:
        bucket_name = event.get('bucket')
        object_key = event.get('key')
        expiration = event.get('expiration', 3600)
        
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={'Bucket': bucket_name, 'Key': object_key},
            ExpiresIn=expiration
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'url': presigned_url})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
