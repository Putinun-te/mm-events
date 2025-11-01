# 🔐 Cognito Authentication + CI/CD Setup Guide

## Overview

Complete setup for:
- ✅ **Cognito Authentication** - User management with Hosted UI
- ✅ **S3 Static Website Hosting** - Direct hosting (CloudFront alternative)
- ✅ **GitHub Actions CI/CD** - Automated deployment pipeline

## 🚀 Quick Start

### Step 1: Deploy Infrastructure

```bash
cd /Users/putinan/development/DevOps/develop/aws

# Import existing IAM groups (already done)
# terraform import aws_iam_group.developers concert-developers
# terraform import aws_iam_group.testers concert-testers
# terraform import aws_iam_group.deployment concert-deployment
# terraform import aws_iam_group.admins concert-admins

# Deploy infrastructure
terraform apply
```

**What gets created:**
- ✅ Cognito User Pool + Web Client
- ✅ Cognito Identity Pool (for AWS SDK)
- ✅ Cognito Hosted UI domain
- ✅ IAM roles for authenticated users
- ✅ S3 static website hosting
- ✅ Enhanced S3 bucket policies

### Step 2: Configure GitHub Secrets

Go to: **GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | IAM user with deployment permissions |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | IAM user secret |
| `EC2_SSH_PRIVATE_KEY` | EC2 private key | For SSH deployment to EC2 |
| `API_BASE_URL` | Backend API URL | E.g., `http://your-ec2-ip:8080` |

**To create AWS access keys:**
```bash
# Create deployment user (if not exists)
aws iam create-user --user-name github-actions-deployer

# Attach policies
aws iam attach-user-policy --user-name github-actions-deployer \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create access key
aws iam create-access-key --user-name github-actions-deployer
```

### Step 3: Get Cognito Configuration

```bash
cd aws

# Get all Cognito configuration for frontend
terraform output frontend_cognito_config
```

**Output example:**
```json
{
  "region": "us-east-1",
  "userPoolId": "us-east-1_ABC123",
  "userPoolWebClientId": "abc123def456...",
  "identityPoolId": "us-east-1:uuid-here",
  "oauth": {
    "domain": "concert-auth-123456789012.auth.us-east-1.amazoncognito.com",
    "scope": ["email", "openid", "profile", "aws.cognito.signin.user.admin"],
    "redirectSignIn": "http://bucket-name.s3-website-us-east-1.amazonaws.com/auth/callback",
    "redirectSignOut": "http://bucket-name.s3-website-us-east-1.amazonaws.com",
    "responseType": "code"
  }
}
```

## 🔐 Frontend Integration (Nuxt)

### Install Amplify Library

```bash
cd main_frontend/concert1
npm install @aws-amplify/auth @aws-amplify/core
```

### Configure Amplify in Nuxt

Create `plugins/amplify.client.ts`:

```typescript
import { Amplify } from '@aws-amplify/core'
import { fetchAuthSession } from '@aws-amplify/auth'

export default defineNuxtPlugin(() => {
  Amplify.configure({
    Auth: {
      Cognito: {
        region: 'us-east-1',
        userPoolId: 'us-east-1_TpsZkFbqO', // From terraform output
        userPoolClientId: '2089udacia4eoge33fgmm0sbca', // From terraform output
        identityPoolId: 'us-east-1:uuid-here', // From terraform output
        loginWith: {
          oauth: {
            domain: 'concert-auth-123456789012.auth.us-east-1.amazoncognito.com',
            scopes: ['email', 'openid', 'profile', 'aws.cognito.signin.user.admin'],
            redirectSignIn: ['http://localhost:3000/auth/callback'],
            redirectSignOut: ['http://localhost:3000'],
            responseType: 'code',
          }
        }
      }
    }
  })
})
```

### Create Authentication Composable

Create `composables/useAuth.ts`:

```typescript
import { signIn, signUp, signOut, getCurrentUser, fetchAuthSession } from '@aws-amplify/auth'

export const useAuth = () => {
  const user = useState('user', () => null)
  const isAuthenticated = computed(() => !!user.value)

  // Sign up new user
  const register = async (email: string, password: string, name: string) => {
    try {
      const { userId } = await signUp({
        username: email,
        password,
        options: {
          userAttributes: {
            email,
            name
          }
        }
      })
      return { success: true, userId }
    } catch (error) {
      console.error('Sign up error:', error)
      return { success: false, error }
    }
  }

  // Sign in user
  const login = async (email: string, password: string) => {
    try {
      const { isSignedIn } = await signIn({ username: email, password })
      if (isSignedIn) {
        const currentUser = await getCurrentUser()
        user.value = currentUser
      }
      return { success: true }
    } catch (error) {
      console.error('Sign in error:', error)
      return { success: false, error }
    }
  }

  // Sign out user
  const logout = async () => {
    try {
      await signOut()
      user.value = null
      return { success: true }
    } catch (error) {
      console.error('Sign out error:', error)
      return { success: false, error }
    }
  }

  // Get current session
  const getSession = async () => {
    try {
      const session = await fetchAuthSession()
      return session
    } catch (error) {
      console.error('Get session error:', error)
      return null
    }
  }

  // Check current user on mount
  const checkAuth = async () => {
    try {
      const currentUser = await getCurrentUser()
      user.value = currentUser
    } catch (error) {
      user.value = null
    }
  }

  return {
    user,
    isAuthenticated,
    register,
    login,
    logout,
    getSession,
    checkAuth
  }
}
```

### Create Login Page

Create `pages/login.vue`:

```vue
<template>
  <div class="min-h-screen flex items-center justify-center">
    <div class="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow">
      <h2 class="text-3xl font-bold text-center">Sign In</h2>
      
      <form @submit.prevent="handleLogin" class="space-y-6">
        <div>
          <label class="block text-sm font-medium">Email</label>
          <input
            v-model="email"
            type="email"
            required
            class="mt-1 block w-full px-3 py-2 border rounded-md"
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium">Password</label>
          <input
            v-model="password"
            type="password"
            required
            class="mt-1 block w-full px-3 py-2 border rounded-md"
          />
        </div>

        <button
          type="submit"
          class="w-full py-2 px-4 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Sign In
        </button>
      </form>

      <!-- Hosted UI Button -->
      <div class="text-center">
        <button
          @click="signInWithHostedUI"
          class="w-full py-2 px-4 bg-gray-600 text-white rounded-md hover:bg-gray-700"
        >
          Sign In with Hosted UI
        </button>
      </div>

      <div class="text-center">
        <NuxtLink to="/register" class="text-blue-600 hover:underline">
          Don't have an account? Sign up
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { signInWithRedirect } from '@aws-amplify/auth'

const { login } = useAuth()
const router = useRouter()

const email = ref('')
const password = ref('')

const handleLogin = async () => {
  const result = await login(email.value, password.value)
  if (result.success) {
    router.push('/')
  } else {
    alert('Login failed: ' + result.error)
  }
}

const signInWithHostedUI = async () => {
  await signInWithRedirect()
}
</script>
```

### Create Auth Callback Page

Create `pages/auth/callback.vue`:

```vue
<template>
  <div class="min-h-screen flex items-center justify-center">
    <div class="text-center">
      <h2 class="text-2xl font-bold">Signing you in...</h2>
      <p class="text-gray-600 mt-2">Please wait</p>
    </div>
  </div>
</template>

<script setup lang="ts">
const { checkAuth } = useAuth()
const router = useRouter()

onMounted(async () => {
  await checkAuth()
  router.push('/')
})
</script>
```

## 🚀 CI/CD Pipeline

### Workflow Overview

The GitHub Actions workflow (`.github/workflows/deploy-to-aws.yml`) automatically:

1. **On Push to `main` or `develop`:**
   - ✅ Builds backend (Spring Boot)
   - ✅ Runs backend tests
   - ✅ Builds frontend (Nuxt)
   - ✅ Runs frontend tests
   - ✅ Deploys infrastructure (Terraform)
   - ✅ Deploys frontend to S3
   - ✅ Deploys backend to EC2
   - ✅ Runs integration tests
   - ✅ Sends notifications

2. **On Pull Request:**
   - ✅ Builds and tests code
   - ✅ Comments PR with preview URL

### Trigger Deployment

```bash
# Commit your changes
git add .
git commit -m "feat: add Cognito authentication"

# Push to main (triggers full deployment)
git push origin main

# Or push to develop (triggers build + test + deploy to staging)
git push origin develop
```

### Monitor Deployment

1. Go to GitHub → **Actions** tab
2. Click on the running workflow
3. View real-time logs for each job

### Deployment URLs

After successful deployment:

```bash
# Get frontend URL
cd aws
terraform output -raw s3_website_url

# Get Cognito Hosted UI URL
terraform output cognito_hosted_ui_url

# Get Cognito login URL
terraform output cognito_login_url
```

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         GitHub Actions                       │
│  - Build backend (Maven)                                     │
│  - Build frontend (npm)                                      │
│  - Deploy infrastructure (Terraform)                         │
│  - Deploy to AWS                                             │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                         AWS CLOUD                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────┐    ┌──────────────────┐                │
│  │   Cognito       │    │   S3 Frontend    │                │
│  │   User Pool     │◄───┤   Static Website │                │
│  │   + Identity    │    │   (Public Access)│                │
│  │   Pool          │    └──────────────────┘                │
│  └─────────────────┘                                         │
│          │                                                    │
│          │ Auth                                               │
│          ▼                                                    │
│  ┌─────────────────┐    ┌──────────────────┐                │
│  │   EC2 Backend   │◄───│   RDS MySQL      │                │
│  │   Spring Boot   │    │   Database       │                │
│  │   Auto Scaling  │    └──────────────────┘                │
│  └─────────────────┘                                         │
│          │                                                    │
│          ▼                                                    │
│  ┌─────────────────┐    ┌──────────────────┐                │
│  │  ElastiCache    │    │   S3 Images      │                │
│  │  Redis Cache    │    │   (Events/       │                │
│  └─────────────────┘    │    Avatars)      │                │
│                         └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 🔒 Security Best Practices

### Cognito User Pool Security

```bash
# Enable MFA (optional)
aws cognito-idp set-user-pool-mfa-config \
  --user-pool-id us-east-1_TpsZkFbqO \
  --mfa-configuration OPTIONAL \
  --software-token-mfa-configuration Enabled=true

# Set password policy (already configured in Terraform)
# - Minimum 8 characters
# - Require uppercase
# - Require lowercase
# - Require numbers
# - Require symbols
```

### S3 Bucket Security

The buckets are configured with:
- ✅ Versioning enabled (rollback capability)
- ✅ CORS configured properly
- ✅ Authenticated users can only upload to their own folder
- ✅ Public read access for images (via bucket policy)

### IAM Least Privilege

Cognito authenticated users can only:
- Upload to: `s3://user-avatars/users/{user-id}/*`
- Read from: Public buckets only
- Cannot delete other users' files

## 📋 Post-Deployment Checklist

- [ ] Infrastructure deployed successfully
- [ ] Cognito User Pool created
- [ ] S3 frontend bucket accessible
- [ ] GitHub Actions secrets configured
- [ ] First deployment successful
- [ ] Frontend loads at S3 URL
- [ ] Cognito login works
- [ ] User can sign up
- [ ] User can upload avatar
- [ ] Backend API accessible
- [ ] Database connection working

## 🔧 Troubleshooting

### CloudFront Error (Account Not Verified)

**Error:** `Your account must be verified before you can add new CloudFront resources`

**Solution:** 
1. CloudFront is disabled for now
2. Using S3 static website hosting instead
3. To enable CloudFront later:
   - Contact AWS Support
   - Verify your account
   - Rename `cloudfront.tf.disabled` → `cloudfront.tf`
   - Run `terraform apply`

### Cognito Redirect Not Working

**Check:**
1. Callback URLs match exactly (including protocol)
2. Frontend running on correct URL
3. OAuth scope includes required permissions

**Fix:**
```bash
# Update callback URLs in Terraform
# Edit: cognito_web_integration.tf
# Add your frontend URL to callback_urls array
terraform apply
```

### S3 Website Not Accessible

**Check public access block:**
```bash
aws s3api get-public-access-block \
  --bucket concert-dev-frontend-d453b7db
```

**Enable public website access:**
```bash
aws s3api delete-public-access-block \
  --bucket concert-dev-frontend-d453b7db
```

### GitHub Actions Failing

**Check secrets:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check EC2 SSH key
ssh -i ec2-key.pem ec2-user@<ec2-ip>
```

## 📚 Useful Commands

```bash
# Get all Terraform outputs
terraform output

# Get Cognito config only
terraform output frontend_cognito_config

# Test Cognito authentication
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_TpsZkFbqO \
  --username test@example.com \
  --temporary-password "TempPass123!"

# Sync local files to S3
aws s3 sync ./main_frontend/concert1/.output/public \
  s3://concert-dev-frontend-d453b7db \
  --delete

# View CloudWatch logs
aws logs tail /aws/concert/application --follow

# List all deployments
git log --oneline --graph

# View GitHub Actions runs
gh run list
gh run view <run-id>
```

## 🎉 Success!

Your application now has:
- ✅ **Authentication** - Cognito with Hosted UI
- ✅ **Static Hosting** - S3 website hosting
- ✅ **CI/CD Pipeline** - GitHub Actions automation
- ✅ **Secure Access** - IAM roles for AWS resources
- ✅ **Monitoring** - CloudWatch logs and metrics

**Next steps:**
1. Customize Cognito Hosted UI (branding, custom domain)
2. Add social identity providers (Google, Facebook)
3. Configure custom domain for S3 website
4. Enable CloudFront when account is verified
5. Set up monitoring alerts
