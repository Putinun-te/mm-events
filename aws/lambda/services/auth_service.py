"""
AUTH-SERVICE Lambda Function
Handles JWT token generation, refresh, and user authentication

Environment Variables:
- JWT_SECRET: JWT signing secret from Secrets Manager
- RDS_HOST: RDS database endpoint
- RDS_USER: RDS username
- RDS_PASSWORD: RDS password
- ENVIRONMENT: dev/test/staging/prod
"""

import json
import os
import jwt
import boto3
from datetime import datetime, timedelta
from typing import Dict, Any, Tuple
import hashlib
import base64
from functools import wraps

# AWS Clients
secrets_client = boto3.client('secretsmanager')
dynamodb = boto3.resource('dynamodb')
rds_client = boto3.client('rds')
cloudwatch = boto3.client('cloudwatch')

# Environment Variables
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')
JWT_EXPIRY = 3600  # 1 hour
REFRESH_TOKEN_EXPIRY = 86400 * 7  # 7 days

# DynamoDB Tables
session_tokens_table = dynamodb.Table(f'concert-session-tokens-{ENVIRONMENT}')


def get_jwt_secret() -> str:
    """Retrieve JWT secret from Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(
            SecretId=f'concert-jwt-secret-{ENVIRONMENT}'
        )
        return response['SecretString']
    except Exception as e:
        print(f"Error retrieving JWT secret: {str(e)}")
        return os.environ.get('JWT_SECRET', 'default-secret')


def hash_password(password: str) -> str:
    """Hash password with salt"""
    salt = os.urandom(32)
    pwd_hash = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 100000)
    return base64.b64encode(salt + pwd_hash).decode()


def verify_password(stored_hash: str, provided_password: str) -> bool:
    """Verify password against hash"""
    try:
        decoded = base64.b64decode(stored_hash)
        salt = decoded[:32]
        stored_pwd_hash = decoded[32:]
        pwd_hash = hashlib.pbkdf2_hmac('sha256', provided_password.encode(), salt, 100000)
        return pwd_hash == stored_pwd_hash
    except Exception as e:
        print(f"Error verifying password: {str(e)}")
        return False


def generate_jwt_token(user_id: str, user_email: str, additional_claims: Dict = None) -> str:
    """Generate JWT token"""
    try:
        secret = get_jwt_secret()
        payload = {
            'user_id': user_id,
            'email': user_email,
            'iat': datetime.utcnow(),
            'exp': datetime.utcnow() + timedelta(seconds=JWT_EXPIRY),
            'type': 'access'
        }
        
        if additional_claims:
            payload.update(additional_claims)
        
        token = jwt.encode(payload, secret, algorithm='HS256')
        return token
    except Exception as e:
        print(f"Error generating JWT: {str(e)}")
        raise


def generate_refresh_token(user_id: str) -> str:
    """Generate refresh token"""
    try:
        secret = get_jwt_secret()
        payload = {
            'user_id': user_id,
            'iat': datetime.utcnow(),
            'exp': datetime.utcnow() + timedelta(seconds=REFRESH_TOKEN_EXPIRY),
            'type': 'refresh'
        }
        
        token = jwt.encode(payload, secret, algorithm='HS256')
        
        # Store refresh token in DynamoDB
        session_tokens_table.put_item(
            Item={
                'token_id': token,
                'user_id': user_id,
                'expires_at': int((datetime.utcnow() + timedelta(seconds=REFRESH_TOKEN_EXPIRY)).timestamp()),
                'created_at': int(datetime.utcnow().timestamp()),
                'type': 'refresh'
            }
        )
        
        return token
    except Exception as e:
        print(f"Error generating refresh token: {str(e)}")
        raise


def verify_jwt_token(token: str) -> Tuple[bool, Dict]:
    """Verify JWT token"""
    try:
        secret = get_jwt_secret()
        payload = jwt.decode(token, secret, algorithms=['HS256'])
        return True, payload
    except jwt.ExpiredSignatureError:
        return False, {'error': 'Token expired'}
    except jwt.InvalidTokenError:
        return False, {'error': 'Invalid token'}
    except Exception as e:
        print(f"Error verifying token: {str(e)}")
        return False, {'error': 'Token verification failed'}


def lambda_handler(event, context) -> Dict[str, Any]:
    """Main Lambda handler"""
    
    try:
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        body = json.loads(event.get('body', '{}')) if event.get('body') else {}
        
        # Routes
        if path == '/api/auth/register' and http_method == 'POST':
            return handle_register(body)
        
        elif path == '/api/auth/login' and http_method == 'POST':
            return handle_login(body)
        
        elif path == '/api/auth/refresh' and http_method == 'POST':
            return handle_refresh(body)
        
        elif path == '/api/auth/verify' and http_method == 'GET':
            auth_header = event.get('headers', {}).get('Authorization', '')
            return handle_verify(auth_header)
        
        elif path == '/api/auth/logout' and http_method == 'POST':
            return handle_logout(body)
        
        else:
            return error_response(404, 'Route not found')
    
    except Exception as e:
        print(f"Error in auth service: {str(e)}")
        return error_response(500, 'Internal server error')


def handle_register(body: Dict) -> Dict:
    """Handle user registration"""
    email = body.get('email')
    password = body.get('password')
    name = body.get('name')
    
    if not all([email, password, name]):
        return error_response(400, 'Missing required fields')
    
    if len(password) < 8:
        return error_response(400, 'Password must be at least 8 characters')
    
    try:
        # Hash password
        password_hash = hash_password(password)
        
        # TODO: Store in RDS MySQL
        user_id = generate_user_id(email)
        
        # Generate tokens
        access_token = generate_jwt_token(user_id, email)
        refresh_token = generate_refresh_token(user_id)
        
        # Log metrics
        cloudwatch.put_metric_data(
            Namespace='Concert/Auth',
            MetricData=[
                {
                    'MetricName': 'UserRegistration',
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )
        
        return success_response({
            'user_id': user_id,
            'email': email,
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': JWT_EXPIRY
        })
    
    except Exception as e:
        print(f"Registration error: {str(e)}")
        return error_response(500, 'Registration failed')


def handle_login(body: Dict) -> Dict:
    """Handle user login"""
    email = body.get('email')
    password = body.get('password')
    
    if not all([email, password]):
        return error_response(400, 'Missing email or password')
    
    try:
        # TODO: Verify credentials from RDS MySQL
        user_id = verify_user_credentials(email, password)
        
        if not user_id:
            return error_response(401, 'Invalid credentials')
        
        # Generate tokens
        access_token = generate_jwt_token(user_id, email)
        refresh_token = generate_refresh_token(user_id)
        
        # Log metrics
        cloudwatch.put_metric_data(
            Namespace='Concert/Auth',
            MetricData=[
                {
                    'MetricName': 'UserLogin',
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )
        
        return success_response({
            'user_id': user_id,
            'email': email,
            'access_token': access_token,
            'refresh_token': refresh_token,
            'expires_in': JWT_EXPIRY
        })
    
    except Exception as e:
        print(f"Login error: {str(e)}")
        return error_response(500, 'Login failed')


def handle_refresh(body: Dict) -> Dict:
    """Handle token refresh"""
    refresh_token = body.get('refresh_token')
    
    if not refresh_token:
        return error_response(400, 'Missing refresh_token')
    
    try:
        valid, payload = verify_jwt_token(refresh_token)
        
        if not valid or payload.get('type') != 'refresh':
            return error_response(401, 'Invalid refresh token')
        
        user_id = payload['user_id']
        email = payload.get('email')
        
        # Generate new access token
        access_token = generate_jwt_token(user_id, email)
        
        return success_response({
            'access_token': access_token,
            'expires_in': JWT_EXPIRY
        })
    
    except Exception as e:
        print(f"Refresh error: {str(e)}")
        return error_response(500, 'Token refresh failed')


def handle_verify(auth_header: str) -> Dict:
    """Verify token validity"""
    if not auth_header.startswith('Bearer '):
        return error_response(401, 'Missing or invalid authorization header')
    
    token = auth_header[7:]
    valid, payload = verify_jwt_token(token)
    
    if not valid:
        return error_response(401, 'Invalid or expired token')
    
    return success_response({
        'valid': True,
        'user_id': payload.get('user_id'),
        'email': payload.get('email'),
        'expires_at': payload.get('exp')
    })


def handle_logout(body: Dict) -> Dict:
    """Handle logout"""
    token = body.get('token')
    
    if token:
        # TODO: Invalidate token in DynamoDB
        pass
    
    return success_response({'message': 'Logged out successfully'})


def generate_user_id(email: str) -> str:
    """Generate unique user ID"""
    return f"user-{hashlib.md5(email.encode()).hexdigest()[:12]}"


def verify_user_credentials(email: str, password: str) -> str:
    """Verify user credentials (placeholder for RDS integration)"""
    # TODO: Query RDS for user and verify password
    return None


def success_response(data: Dict) -> Dict:
    """Format success response"""
    return {
        'statusCode': 200,
        'body': json.dumps(data),
        'headers': {
            'Content-Type': 'application/json'
        }
    }


def error_response(status_code: int, message: str) -> Dict:
    """Format error response"""
    return {
        'statusCode': status_code,
        'body': json.dumps({'error': message}),
        'headers': {
            'Content-Type': 'application/json'
        }
    }
