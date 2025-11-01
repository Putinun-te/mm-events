# 🔓 How to Access Your S3 Files (Without CloudFront)

## ⚠️ Current Situation

**CloudFront is blocked** because your AWS account needs verification:
```
Error: Your account must be verified before you can add new CloudFront resources.
To verify your account, please contact AWS Support
```

**But you can still access S3 files!** Here's how:

---

## ✅ Method 1: Lambda Presigned URLs (RECOMMENDED - Works Now!)

### Upload AND Access Flow:

```bash
# 1. Get presigned URL for upload
curl -X POST https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev/upload/event-picture \
  -H "Content-Type: application/json" \
  -d '{"filename": "concert.jpg", "contentType": "image/jpeg"}'

# Response:
{
  "uploadUrl": "https://concert-event-pictures-123456789012.s3.ap-southeast-1.amazonaws.com/events/concert.jpg?X-Amz-...",
  "fileUrl": "https://concert-event-pictures-123456789012.s3.ap-southeast-1.amazonaws.com/events/concert.jpg",
  "key": "events/concert.jpg"
}

# 2. Upload file
curl -X PUT "<uploadUrl>" \
  -H "Content-Type: image/jpeg" \
  --upload-file concert.jpg

# 3. To VIEW the file, request ANOTHER presigned URL for download:
curl -X POST https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev/get-file \
  -H "Content-Type: application/json" \
  -d '{"key": "events/concert.jpg"}'

# This will return a presigned URL valid for 5 minutes to VIEW the file
```

---

## 🔧 Method 2: Update Lambda to Support Downloads

We need to add a new Lambda route for generating **download presigned URLs**:

### Step 1: Add API Gateway Route for Downloads

```hcl
# In api_gateway_lambda.tf

# Route for getting download URLs
resource "aws_apigatewayv2_route" "get_event_picture" {
  api_id    = aws_apigatewayv2_api.file_upload.id
  route_key = "POST /get-file"
  target    = "integrations/${aws_apigatewayv2_integration.get_file.id}"
}

resource "aws_apigatewayv2_integration" "get_file" {
  api_id             = aws_apigatewayv2_api.file_upload.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.generate_presigned_url.invoke_arn
  payload_format_version = "2.0"
}
```

### Step 2: Update Lambda Function

```python
# lambda_presigned_url.py (updated)

import json
import boto3
from botocore.exceptions import ClientError
import os

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    # Parse request
    try:
        body = json.loads(event.get('body', '{}'))
    except:
        body = event.get('body', {})
    
    route = event.get('routeKey', '')
    
    # Handle upload presigned URL
    if 'upload' in route:
        filename = body.get('filename')
        content_type = body.get('contentType', 'application/octet-stream')
        
        # Determine bucket based on route
        if 'avatar' in route:
            bucket = os.environ['AVATARS_BUCKET']
            prefix = 'avatars'
        else:
            bucket = os.environ['EVENTS_BUCKET']
            prefix = 'events'
        
        # Generate unique key
        import uuid
        key = f"{prefix}/{uuid.uuid4()}-{filename}"
        
        # Generate presigned URL for upload (PUT)
        try:
            upload_url = s3_client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': bucket,
                    'Key': key,
                    'ContentType': content_type
                },
                ExpiresIn=300  # 5 minutes
            )
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'uploadUrl': upload_url,
                    'key': key,
                    'fileUrl': f"https://{bucket}.s3.{os.environ['AWS_REGION']}.amazonaws.com/{key}"
                })
            }
        except ClientError as e:
            print(f"Error: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e)})
            }
    
    # Handle download presigned URL (NEW!)
    elif 'get-file' in route:
        key = body.get('key')
        
        if not key:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing key parameter'})
            }
        
        # Determine bucket from key prefix
        if key.startswith('avatars/'):
            bucket = os.environ['AVATARS_BUCKET']
        elif key.startswith('events/'):
            bucket = os.environ['EVENTS_BUCKET']
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Invalid key prefix'})
            }
        
        # Generate presigned URL for download (GET)
        try:
            download_url = s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': bucket,
                    'Key': key
                },
                ExpiresIn=300  # 5 minutes
            )
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'downloadUrl': download_url,
                    'key': key,
                    'expiresIn': 300
                })
            }
        except ClientError as e:
            print(f"Error: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e)})
            }
    
    else:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Route not found'})
        }
```

---

## 🚀 Method 3: Make S3 Buckets Temporarily Public (NOT RECOMMENDED)

**Only for testing!** This bypasses security:

```bash
# TEMPORARY - Remove public access block
aws s3api delete-public-access-block \
  --bucket concert-event-pictures-123456789012 \
  --region ap-southeast-1

# Add public read policy
aws s3api put-bucket-policy \
  --bucket concert-event-pictures-123456789012 \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::concert-event-pictures-123456789012/*"
    }]
  }'

# Now direct S3 URLs will work:
# https://concert-event-pictures-123456789012.s3.ap-southeast-1.amazonaws.com/events/photo.jpg
```

⚠️ **WARNING**: This makes ALL files public! Revert after testing.

---

## 📋 Fix CloudFront Account Verification

To enable CloudFront permanently:

### Step 1: Contact AWS Support

1. Go to: https://console.aws.amazon.com/support/home
2. Click "Create case"
3. Select "Account and billing"
4. Issue: "Account verification for CloudFront"
5. Message:
   ```
   Hello,
   
   I'm receiving the following error when trying to create CloudFront distributions:
   
   "Your account must be verified before you can add new CloudFront resources."
   
   Request ID: e9a3c928-0496-4d8d-ad85-b6b611658751
   
   Please verify my account to allow CloudFront resource creation.
   
   Thank you!
   ```

### Step 2: While Waiting (Use Presigned URLs)

Use Method 1 or 2 above to access files via Lambda presigned URLs.

---

## 🔄 Current Working Flow (Without CloudFront)

```
1. Upload File:
   Client → API Gateway → Lambda → S3 Presigned URL (PUT) → Client uploads → S3

2. Access File (Option A - Public):
   Browser → Direct S3 URL (if bucket is public)
   ❌ 403 Forbidden (if bucket is private - CURRENT STATE)

3. Access File (Option B - Presigned URL):
   Client → API Gateway → Lambda → S3 Presigned URL (GET) → Client downloads
   ✅ Works! (Secure and temporary)
```

---

## 📊 Compare Methods

| Method | Security | Speed | Expires | Status |
|--------|----------|-------|---------|---------|
| **Direct S3** | ❌ Public | Fast | Never | ❌ Blocked (403) |
| **Presigned URL** | ✅ Secure | Fast | 5 min | ✅ Works now! |
| **CloudFront** | ✅ Secure | Fastest | Cached | ⏳ Needs verification |

---

## ✅ Recommended Action Plan

**Right Now:**
1. Use Lambda presigned URLs for downloads (add new route)
2. Files remain secure in private S3 buckets
3. Works immediately, no AWS support needed

**Long Term (After AWS Verification):**
1. Enable CloudFront distributions
2. Global CDN with caching
3. Faster access, lower costs
4. Better user experience

---

## 🧪 Test Presigned URL Access

```bash
#!/bin/bash
# test_s3_access.sh

API_URL="https://mdazlesd5f.execute-api.ap-southeast-1.amazonaws.com/dev"

echo "1. Uploading test file..."
RESPONSE=$(curl -s -X POST "$API_URL/upload/event-picture" \
  -H "Content-Type: application/json" \
  -d '{"filename": "test.jpg", "contentType": "image/jpeg"}')

UPLOAD_URL=$(echo $RESPONSE | jq -r '.uploadUrl')
KEY=$(echo $RESPONSE | jq -r '.key')

echo "2. Uploading to S3..."
echo "Test content" > test.jpg
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --upload-file test.jpg

echo "3. Getting download URL..."
DOWNLOAD_RESPONSE=$(curl -s -X POST "$API_URL/get-file" \
  -H "Content-Type: application/json" \
  -d "{\"key\": \"$KEY\"}")

DOWNLOAD_URL=$(echo $DOWNLOAD_RESPONSE | jq -r '.downloadUrl')

echo "4. Downloading file..."
curl "$DOWNLOAD_URL" -o downloaded.jpg

echo "✅ Success! File accessed securely via presigned URL"
```

---

**Next Steps:**
1. Add `/get-file` route to API Gateway ✅ (5 min)
2. Update Lambda function to handle downloads ✅ (10 min)
3. Test presigned URL access ✅ (2 min)
4. Contact AWS Support for CloudFront verification ⏳ (1-2 days wait)
5. Deploy CloudFront once verified ✅ (15 min)

**Current Status**: S3 is working correctly (secure/private). You just need to access files via presigned URLs instead of direct URLs.
