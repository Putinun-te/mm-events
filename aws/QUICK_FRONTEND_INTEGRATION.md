# Quick Frontend Integration Guide

## 🎯 Goal
Add AWS Cognito authentication to the Nuxt 4 frontend in 5 files.

## ✅ Prerequisites
- Infrastructure deployed (Cognito User Pool created)
- Cognito config from terraform output

---

## Step 1: Install Dependencies

```bash
cd main_frontend/concert1
npm install @aws-amplify/auth @aws-amplify/core
```

---

## Step 2: Create Amplify Plugin

**File**: `main_frontend/concert1/plugins/amplify.client.ts`

```typescript
import { Amplify } from '@aws-amplify/core';

export default defineNuxtPlugin(() => {
  // Cognito configuration from terraform output
  Amplify.configure({
    Auth: {
      Cognito: {
        // Identity Pool for AWS SDK credentials
        identityPoolId: "us-east-1:83d2800d-d497-4319-ac2f-5961c3982d48",
        
        // User Pool for authentication
        userPoolId: "us-east-1_TpsZkFbqO",
        userPoolClientId: "1eomnjf6812g8npdr8ta8naem7",
        
        // OAuth configuration (Hosted UI)
        loginWith: {
          oauth: {
            domain: "concert-auth-123456789012.auth.us-east-1.amazoncognito.com",
            scopes: [
              "email",
              "openid",
              "profile",
              "aws.cognito.signin.user.admin"
            ],
            redirectSignIn: ["http://localhost:3000/auth/callback"],
            redirectSignOut: ["http://localhost:3000"],
            responseType: "code"
          }
        }
      }
    }
  });
});
```

---

## Step 3: Create Auth Composable

**File**: `main_frontend/concert1/composables/useAuth.ts`

```typescript
import {
  signUp,
  signIn,
  signOut,
  signInWithRedirect,
  getCurrentUser,
  fetchAuthSession,
  confirmSignUp
} from '@aws-amplify/auth';

export const useAuth = () => {
  // Reactive state
  const user = useState<any>('auth-user', () => null);
  const isAuthenticated = computed(() => !!user.value);

  /**
   * Register new user with email and password
   */
  const register = async (username: string, password: string, email: string) => {
    try {
      const { userId, nextStep } = await signUp({
        username,
        password,
        options: {
          userAttributes: {
            email,
          }
        }
      });

      console.log('User registered:', userId);
      console.log('Next step:', nextStep);
      
      return { userId, nextStep };
    } catch (error: any) {
      console.error('Registration error:', error);
      throw new Error(error.message || 'Registration failed');
    }
  };

  /**
   * Confirm user registration with verification code
   */
  const confirmRegistration = async (username: string, code: string) => {
    try {
      const { isSignUpComplete } = await confirmSignUp({
        username,
        confirmationCode: code
      });
      return isSignUpComplete;
    } catch (error: any) {
      console.error('Confirmation error:', error);
      throw new Error(error.message || 'Confirmation failed');
    }
  };

  /**
   * Sign in with username and password
   */
  const login = async (username: string, password: string) => {
    try {
      const { isSignedIn, nextStep } = await signIn({
        username,
        password
      });

      if (isSignedIn) {
        user.value = await getCurrentUser();
      }

      return { isSignedIn, nextStep };
    } catch (error: any) {
      console.error('Login error:', error);
      throw new Error(error.message || 'Login failed');
    }
  };

  /**
   * Sign in with Cognito Hosted UI
   */
  const loginWithHostedUI = async () => {
    try {
      await signInWithRedirect({
        provider: 'Cognito'
      });
    } catch (error: any) {
      console.error('Hosted UI login error:', error);
      throw new Error(error.message || 'Hosted UI login failed');
    }
  };

  /**
   * Sign out current user
   */
  const logout = async () => {
    try {
      await signOut();
      user.value = null;
    } catch (error: any) {
      console.error('Logout error:', error);
      throw new Error(error.message || 'Logout failed');
    }
  };

  /**
   * Get current authenticated user
   */
  const getUser = async () => {
    try {
      const currentUser = await getCurrentUser();
      user.value = currentUser;
      return currentUser;
    } catch (error) {
      user.value = null;
      return null;
    }
  };

  /**
   * Get JWT token for API calls
   */
  const getToken = async () => {
    try {
      const session = await fetchAuthSession();
      return session.tokens?.idToken?.toString();
    } catch (error) {
      console.error('Get token error:', error);
      return null;
    }
  };

  /**
   * Get AWS credentials for S3 uploads
   */
  const getCredentials = async () => {
    try {
      const session = await fetchAuthSession();
      return session.credentials;
    } catch (error) {
      console.error('Get credentials error:', error);
      return null;
    }
  };

  return {
    // State
    user,
    isAuthenticated,

    // Methods
    register,
    confirmRegistration,
    login,
    loginWithHostedUI,
    logout,
    getUser,
    getToken,
    getCredentials
  };
};
```

---

## Step 4: Create Login Page

**File**: `main_frontend/concert1/app/pages/login.vue`

```vue
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Sign in to Concert
        </h2>
      </div>

      <!-- Quick Option: Hosted UI -->
      <div class="rounded-md shadow">
        <button
          @click="handleHostedUILogin"
          class="w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Sign in with Hosted UI
        </button>
      </div>

      <div class="relative">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-gray-300" />
        </div>
        <div class="relative flex justify-center text-sm">
          <span class="px-2 bg-gray-50 text-gray-500">Or sign in manually</span>
        </div>
      </div>

      <!-- Manual Login Form -->
      <form @submit.prevent="handleManualLogin" class="mt-8 space-y-6">
        <div class="rounded-md shadow-sm -space-y-px">
          <div>
            <label for="username" class="sr-only">Username</label>
            <input
              id="username"
              v-model="username"
              type="text"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
              placeholder="Username"
            />
          </div>
          <div>
            <label for="password" class="sr-only">Password</label>
            <input
              id="password"
              v-model="password"
              type="password"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
              placeholder="Password"
            />
          </div>
        </div>

        <div v-if="error" class="rounded-md bg-red-50 p-4">
          <div class="flex">
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">{{ error }}</h3>
            </div>
          </div>
        </div>

        <div>
          <button
            type="submit"
            :disabled="loading"
            class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            {{ loading ? 'Signing in...' : 'Sign in' }}
          </button>
        </div>

        <div class="text-center">
          <NuxtLink to="/register" class="font-medium text-indigo-600 hover:text-indigo-500">
            Don't have an account? Sign up
          </NuxtLink>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
const { login, loginWithHostedUI } = useAuth();
const router = useRouter();

const username = ref('');
const password = ref('');
const error = ref('');
const loading = ref(false);

const handleHostedUILogin = async () => {
  try {
    await loginWithHostedUI();
    // User will be redirected to Cognito Hosted UI
  } catch (e: any) {
    error.value = e.message;
  }
};

const handleManualLogin = async () => {
  loading.value = true;
  error.value = '';

  try {
    const { isSignedIn } = await login(username.value, password.value);
    if (isSignedIn) {
      router.push('/');
    }
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
};
</script>
```

---

## Step 5: Create Register Page

**File**: `main_frontend/concert1/app/pages/register.vue`

```vue
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Create your account
        </h2>
      </div>

      <form v-if="!needsConfirmation" @submit.prevent="handleRegister" class="mt-8 space-y-6">
        <div class="rounded-md shadow-sm -space-y-px">
          <div>
            <input
              v-model="username"
              type="text"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Username"
            />
          </div>
          <div>
            <input
              v-model="email"
              type="email"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Email address"
            />
          </div>
          <div>
            <input
              v-model="password"
              type="password"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="Password (min 8 chars)"
            />
          </div>
        </div>

        <div v-if="error" class="rounded-md bg-red-50 p-4">
          <p class="text-sm font-medium text-red-800">{{ error }}</p>
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          {{ loading ? 'Creating account...' : 'Sign up' }}
        </button>

        <div class="text-center">
          <NuxtLink to="/login" class="font-medium text-indigo-600 hover:text-indigo-500">
            Already have an account? Sign in
          </NuxtLink>
        </div>
      </form>

      <!-- Confirmation Form -->
      <form v-else @submit.prevent="handleConfirmation" class="mt-8 space-y-6">
        <div>
          <p class="text-center text-sm text-gray-600 mb-4">
            We sent a verification code to <strong>{{ email }}</strong>
          </p>
          <input
            v-model="confirmationCode"
            type="text"
            required
            class="appearance-none rounded relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            placeholder="Enter verification code"
          />
        </div>

        <div v-if="error" class="rounded-md bg-red-50 p-4">
          <p class="text-sm font-medium text-red-800">{{ error }}</p>
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
        >
          {{ loading ? 'Confirming...' : 'Confirm' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
const { register, confirmRegistration } = useAuth();
const router = useRouter();

const username = ref('');
const email = ref('');
const password = ref('');
const confirmationCode = ref('');
const error = ref('');
const loading = ref(false);
const needsConfirmation = ref(false);

const handleRegister = async () => {
  loading.value = true;
  error.value = '';

  try {
    const { nextStep } = await register(
      username.value,
      password.value,
      email.value
    );

    if (nextStep.signUpStep === 'CONFIRM_SIGN_UP') {
      needsConfirmation.value = true;
    }
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
};

const handleConfirmation = async () => {
  loading.value = true;
  error.value = '';

  try {
    await confirmRegistration(username.value, confirmationCode.value);
    router.push('/login');
  } catch (e: any) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
};
</script>
```

---

## Step 6: Create OAuth Callback Handler

**File**: `main_frontend/concert1/app/pages/auth/callback.vue`

```vue
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50">
    <div class="text-center">
      <div v-if="loading" class="space-y-4">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
        <p class="text-gray-600">Completing sign in...</p>
      </div>
      
      <div v-else-if="error" class="space-y-4">
        <p class="text-red-600">{{ error }}</p>
        <NuxtLink to="/login" class="text-indigo-600 hover:text-indigo-500">
          Back to login
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const { getUser } = useAuth();
const router = useRouter();

const loading = ref(true);
const error = ref('');

onMounted(async () => {
  try {
    // Get current user after OAuth redirect
    const user = await getUser();
    
    if (user) {
      console.log('Successfully logged in:', user);
      // Redirect to home page
      router.push('/');
    } else {
      throw new Error('No user found after OAuth callback');
    }
  } catch (e: any) {
    console.error('OAuth callback error:', e);
    error.value = e.message || 'Authentication failed';
    
    // Redirect to login after 3 seconds
    setTimeout(() => {
      router.push('/login');
    }, 3000);
  } finally {
    loading.value = false;
  }
});
</script>
```

---

## Step 7: Update Navigation (Optional)

Add login/logout buttons to your layout or navbar:

**File**: `main_frontend/concert1/app/components/NavBar.vue` (or similar)

```vue
<template>
  <nav class="bg-white shadow">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between h-16">
        <div class="flex items-center">
          <NuxtLink to="/" class="text-xl font-bold text-indigo-600">
            Concert
          </NuxtLink>
        </div>

        <div class="flex items-center space-x-4">
          <template v-if="isAuthenticated">
            <span class="text-gray-700">{{ user?.username }}</span>
            <button
              @click="handleLogout"
              class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-md"
            >
              Logout
            </button>
          </template>
          <template v-else>
            <NuxtLink
              to="/login"
              class="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900"
            >
              Login
            </NuxtLink>
            <NuxtLink
              to="/register"
              class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md"
            >
              Sign up
            </NuxtLink>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup lang="ts">
const { user, isAuthenticated, logout, getUser } = useAuth();
const router = useRouter();

// Check auth status on mount
onMounted(async () => {
  await getUser();
});

const handleLogout = async () => {
  await logout();
  router.push('/');
};
</script>
```

---

## Testing

### 1. Start Development Server
```bash
cd main_frontend/concert1
npm run dev
```

### 2. Test Hosted UI (Recommended)
1. Visit: http://localhost:3000/login
2. Click "Sign in with Hosted UI"
3. Should redirect to Cognito: https://concert-auth-123456789012.auth.us-east-1.amazoncognito.com
4. Create account or sign in
5. Should redirect back to: http://localhost:3000/auth/callback
6. Should then redirect to: http://localhost:3000

### 3. Test Manual Registration
1. Visit: http://localhost:3000/register
2. Enter username, email, password
3. Check email for verification code
4. Enter code to confirm
5. Should redirect to login page

### 4. Test Manual Login
1. Visit: http://localhost:3000/login
2. Enter username and password
3. Should redirect to home page

---

## Making API Calls with Auth

Add authorization header to backend API calls:

```typescript
// In your API composables or services
const { getToken } = useAuth();

const fetchWithAuth = async (url: string, options: RequestInit = {}) => {
  const token = await getToken();
  
  return fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': token ? `Bearer ${token}` : '',
    },
  });
};

// Example: Get user events
const getMyEvents = async () => {
  const response = await fetchWithAuth('http://localhost:8080/api/events/my');
  return response.json();
};
```

---

## File Structure Summary

```
main_frontend/concert1/
├── plugins/
│   └── amplify.client.ts         ← Amplify configuration
├── composables/
│   └── useAuth.ts                ← Authentication composable
├── app/
│   ├── pages/
│   │   ├── login.vue             ← Login page
│   │   ├── register.vue          ← Registration page
│   │   └── auth/
│   │       └── callback.vue      ← OAuth callback handler
│   └── components/
│       └── NavBar.vue            ← (Optional) Nav with login/logout
└── package.json                  ← Dependencies added
```

---

## Common Issues

### "User already exists"
- User already registered. Try signing in instead.

### "Invalid verification code"
- Check email for correct code
- Code may have expired (request new one)

### "Password did not conform with policy"
- Minimum 8 characters
- Must include uppercase, lowercase, number, special char

### Hosted UI doesn't redirect back
- Check callback URL in Cognito matches exactly: `http://localhost:3000/auth/callback`
- Ensure dev server running on port 3000

### "Network error"
- Check internet connection
- Cognito endpoint may be blocked by firewall

---

## Next Steps

1. ✅ Create these 6 files
2. ✅ Test authentication flow
3. ✅ Add protected routes (middleware)
4. ✅ Integrate with backend API
5. ✅ Add user profile page
6. ✅ Implement S3 avatar upload

**Ready to integrate!** 🚀
