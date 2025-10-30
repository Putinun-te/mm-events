import json
import boto3
import os
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

EVENT_PICTURES_BUCKET = os.environ.get('EVENT_PICTURES_BUCKET')
USER_AVATARS_BUCKET = os.environ.get('USER_AVATARS_BUCKET')
PRESIGNED_URL_EXPIRATION = int(os.environ.get('PRESIGNED_URL_EXPIRATION', 3600))


def lambda_handler(event, context):
    """
    Generate pre-signed URL for S3 upload
    Supports both event pictures and user avatars
    """
    try:
        # Parse request
        body = json.loads(event['body'])
        file_type = body.get('fileType')  # 'event-picture' or 'avatar'
        file_name = body.get('fileName')
        entity_id = body.get('entityId')  # eventId or userId
        
        # Validate input
        if not all([file_type, file_name, entity_id]):
            return error_response(400, "Missing required fields: fileType, fileName, entityId")
        
        if file_type not in ['event-picture', 'avatar']:
            return error_response(400, "Invalid fileType. Must be 'event-picture' or 'avatar'")
        
        # Determine bucket and key
        if file_type == 'event-picture':
            bucket = EVENT_PICTURES_BUCKET
            key = f"events/{entity_id}/{file_name}"
            max_file_size = 52428800  # 50MB
        else:  # avatar
            bucket = USER_AVATARS_BUCKET
            key = f"users/{entity_id}/{file_name}"
            max_file_size = 5242880  # 5MB
        
        # Generate pre-signed URL
        presigned_url = s3_client.generate_presigned_post(
            Bucket=bucket,
            Key=key,
            ExpiresIn=PRESIGNED_URL_EXPIRATION,
            Conditions=[
                ["content-length-range", 0, max_file_size],
                ["starts-with", "$Content-Type", "image/"],
            ]
        )
        
        # Calculate expiration time
        expiration_time = (datetime.utcnow() + timedelta(seconds=PRESIGNED_URL_EXPIRATION)).isoformat()
        
        return success_response({
            'uploadUrl': presigned_url['url'],
            'fields': presigned_url['fields'],
            'expiresAt': expiration_time,
            'expirationSeconds': PRESIGNED_URL_EXPIRATION,
            'bucket': bucket,
            'key': key
        })
    
    except KeyError as e:
        print(f"Missing environment variable: {e}")
        return error_response(500, f"Configuration error: {str(e)}")
    
    except Exception as e:
        print(f"Error generating pre-signed URL: {str(e)}")
        return error_response(500, f"Failed to generate pre-signed URL: {str(e)}")


def success_response(data):
    """Format successful response"""
    return {
        'statusCode': 200,
        'body': json.dumps(data),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        }
    }


def error_response(status_code, message):
    """Format error response"""
    return {
        'statusCode': status_code,
        'body': json.dumps({'error': message}),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }
