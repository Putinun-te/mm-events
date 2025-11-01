"""
EVENT-SERVICE Lambda Function
Handles CRUD operations for events, categories, and scheduling

Environment Variables:
- RDS_HOST: RDS database endpoint
- REDIS_ENDPOINT: ElastiCache Redis endpoint
- ENVIRONMENT: dev/test/staging/prod
"""

import json
import boto3
import os
from datetime import datetime
from typing import Dict, Any
import redis

# AWS Clients
dynamodb = boto3.resource('dynamodb')
cloudwatch = boto3.client('cloudwatch')
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')

# Environment
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
event_details_table = dynamodb.Table(f'concert-event-details-{ENVIRONMENT}')

# Redis Connection
redis_client = redis.Redis(
    host=os.environ.get('REDIS_ENDPOINT'),
    port=6379,
    decode_responses=True
)


def lambda_handler(event, context) -> Dict[str, Any]:
    """Main Lambda handler for event service"""
    
    try:
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        
        if path.startswith('/api/events'):
            if 'search' in path:
                return handle_search(event)
            elif path.endswith('/bookings'):
                return handle_get_bookings(event)
            elif http_method == 'GET' and '{id}' in path:
                return handle_get_event(event)
            elif http_method == 'POST':
                return handle_create_event(event)
            elif http_method == 'PUT':
                return handle_update_event(event)
            elif http_method == 'DELETE':
                return handle_delete_event(event)
            else:
                return handle_list_events(event)
        
        return error_response(404, 'Route not found')
    
    except Exception as e:
        print(f"Error in event service: {str(e)}")
        return error_response(500, 'Internal server error')


def handle_list_events(event) -> Dict:
    """List all events with pagination"""
    try:
        # Try to get from cache first
        cached = redis_client.get('events:list:all')
        if cached:
            return success_response(json.loads(cached))
        
        # TODO: Query RDS for events
        events = []  # Placeholder
        
        # Cache for 1 hour
        redis_client.setex('events:list:all', 3600, json.dumps(events))
        
        cloudwatch.put_metric_data(
            Namespace='Concert/Events',
            MetricData=[{'MetricName': 'ListEvents', 'Value': 1}]
        )
        
        return success_response(events)
    except Exception as e:
        print(f"Error listing events: {str(e)}")
        return error_response(500, 'Failed to list events')


def handle_create_event(event) -> Dict:
    """Create new event"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        event_data = {
            'name': body.get('name'),
            'description': body.get('description'),
            'date': body.get('date'),
            'location': body.get('location'),
            'capacity': body.get('capacity'),
            'created_at': datetime.utcnow().isoformat()
        }
        
        # TODO: Store in RDS
        event_id = generate_event_id()
        
        # Store in DynamoDB cache
        event_details_table.put_item(
            Item={
                'event_id': event_id,
                **event_data,
                'expires_at': int(datetime.utcnow().timestamp()) + 3600
            }
        )
        
        # Publish event creation notification
        sns_client.publish(
            TopicArn=os.environ.get('SNS_EVENTS_TOPIC'),
            Subject='New Event Created',
            Message=json.dumps(event_data)
        )
        
        # Invalidate cache
        redis_client.delete('events:list:all')
        
        cloudwatch.put_metric_data(
            Namespace='Concert/Events',
            MetricData=[{'MetricName': 'CreateEvent', 'Value': 1}]
        )
        
        return success_response({'event_id': event_id, **event_data}, 201)
    
    except Exception as e:
        print(f"Error creating event: {str(e)}")
        return error_response(500, 'Failed to create event')


def handle_get_event(event) -> Dict:
    """Get single event by ID"""
    try:
        event_id = event['pathParameters']['id']
        
        # Check DynamoDB cache first
        response = event_details_table.get_item(Key={'event_id': event_id})
        if 'Item' in response:
            return success_response(response['Item'])
        
        # TODO: Query RDS if not in cache
        
        return error_response(404, 'Event not found')
    
    except Exception as e:
        print(f"Error getting event: {str(e)}")
        return error_response(500, 'Failed to get event')


def handle_update_event(event) -> Dict:
    """Update event details"""
    try:
        event_id = event['pathParameters']['id']
        body = json.loads(event.get('body', '{}'))
        
        # TODO: Update in RDS
        
        # Invalidate cache
        redis_client.delete(f'event:{event_id}')
        redis_client.delete('events:list:all')
        
        cloudwatch.put_metric_data(
            Namespace='Concert/Events',
            MetricData=[{'MetricName': 'UpdateEvent', 'Value': 1}]
        )
        
        return success_response({'message': 'Event updated'})
    
    except Exception as e:
        print(f"Error updating event: {str(e)}")
        return error_response(500, 'Failed to update event')


def handle_delete_event(event) -> Dict:
    """Delete event"""
    try:
        event_id = event['pathParameters']['id']
        
        # TODO: Delete from RDS
        
        # Invalidate cache
        redis_client.delete(f'event:{event_id}')
        redis_client.delete('events:list:all')
        
        cloudwatch.put_metric_data(
            Namespace='Concert/Events',
            MetricData=[{'MetricName': 'DeleteEvent', 'Value': 1}]
        )
        
        return success_response({'message': 'Event deleted'})
    
    except Exception as e:
        print(f"Error deleting event: {str(e)}")
        return error_response(500, 'Failed to delete event')


def handle_search(event) -> Dict:
    """Search events by criteria"""
    try:
        query_params = event.get('queryStringParameters', {})
        search_term = query_params.get('q', '')
        
        # TODO: Search in RDS with full-text search
        results = []
        
        return success_response(results)
    
    except Exception as e:
        print(f"Error searching events: {str(e)}")
        return error_response(500, 'Search failed')


def handle_get_bookings(event) -> Dict:
    """Get bookings for a specific event"""
    try:
        event_id = event['pathParameters']['id']
        
        # TODO: Query RDS for bookings
        bookings = []
        
        return success_response(bookings)
    
    except Exception as e:
        print(f"Error getting bookings: {str(e)}")
        return error_response(500, 'Failed to get bookings')


def generate_event_id() -> str:
    """Generate unique event ID"""
    import uuid
    return f"event-{str(uuid.uuid4())[:8]}"


def success_response(data: Dict, status_code: int = 200) -> Dict:
    """Format success response"""
    return {
        'statusCode': status_code,
        'body': json.dumps(data),
        'headers': {'Content-Type': 'application/json'}
    }


def error_response(status_code: int, message: str) -> Dict:
    """Format error response"""
    return {
        'statusCode': status_code,
        'body': json.dumps({'error': message}),
        'headers': {'Content-Type': 'application/json'}
    }
