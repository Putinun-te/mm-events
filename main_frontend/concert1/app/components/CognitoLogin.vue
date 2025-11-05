<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-purple-900 via-purple-800 to-indigo-900 p-4">
    <div class="w-full max-w-md">
      <div class="bg-white/10 backdrop-blur-lg rounded-2xl shadow-2xl p-8 border border-white/20">
        <h2 class="text-3xl font-bold text-white mb-6 text-center">
          {{ showConfirmation ? 'Verify Email' : (isRegisterMode ? 'Sign Up' : 'Sign In') }}
        </h2>
        
        <!-- Confirmation Code Form -->
        <form v-if="showConfirmation" @submit.prevent="handleConfirmation" class="space-y-4">
          <div>
            <label class="block text-white text-sm font-medium mb-2">Verification Code</label>
            <input
              v-model="confirmationCode"
              type="text"
              placeholder="Enter 6-digit code"
              class="w-full px-4 py-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-purple-400"
              required
            />
            <p class="text-white/70 text-xs mt-1">Check your email for the verification code</p>
          </div>

          <div v-if="message" :class="['p-3 rounded-lg text-sm', isSuccess ? 'bg-green-500/20 text-green-200' : 'bg-red-500/20 text-red-200']">
            {{ message }}
          </div>

          <button
            type="submit"
            :disabled="isLoading"
            class="w-full bg-purple-600 hover:bg-purple-700 text-white font-semibold py-3 px-4 rounded-lg transition duration-200 disabled:opacity-50"
          >
            {{ isLoading ? 'Verifying...' : 'Verify Email' }}
          </button>

          <button
            type="button"
            @click="handleResendCode"
            class="w-full text-white/70 hover:text-white text-sm underline"
          >
            Resend Code
          </button>
        </form>

        <!-- Login/Register Form -->
        <form v-else @submit.prevent="handleSubmit" class="space-y-4">
          <div v-if="isRegisterMode">
            <label class="block text-white text-sm font-medium mb-2">Username</label>
            <input
              v-model="username"
              type="text"
              placeholder="Choose a username"
              class="w-full px-4 py-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-purple-400"
              required
            />
          </div>

          <div>
            <label class="block text-white text-sm font-medium mb-2">Email</label>
            <input
              v-model="email"
              type="email"
              placeholder="Enter your email"
              class="w-full px-4 py-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-purple-400"
              required
            />
          </div>

          <div>
            <label class="block text-white text-sm font-medium mb-2">Password</label>
            <div class="relative">
              <input
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                placeholder="Enter your password"
                class="w-full px-4 py-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-purple-400"
                required
              />
              <button
                type="button"
                @click="togglePasswordVisibility"
                class="absolute right-3 top-1/2 transform -translate-y-1/2 text-white/70 hover:text-white"
              >
                {{ showPassword ? '🙈' : '👁️' }}
              </button>
            </div>
            <p v-if="isRegisterMode" class="text-white/70 text-xs mt-1">
              Min 8 chars, include uppercase, lowercase, and number
            </p>
          </div>

          <div v-if="message" :class="['p-3 rounded-lg text-sm', isSuccess ? 'bg-green-500/20 text-green-200' : 'bg-red-500/20 text-red-200']">
            {{ message }}
          </div>

          <button
            type="submit"
            :disabled="isLoading"
            class="w-full bg-purple-600 hover:bg-purple-700 text-white font-semibold py-3 px-4 rounded-lg transition duration-200 disabled:opacity-50"
          >
            {{ isLoading ? 'Processing...' : (isRegisterMode ? 'Create Account' : 'Sign In') }}
          </button>

          <div class="text-center">
            <button
              type="button"
              @click="toggleMode"
              class="text-white/70 hover:text-white text-sm underline"
            >
              {{ isRegisterMode ? 'Already have an account? Sign In' : "Don't have an account? Sign Up" }}
            </button>
          </div>
        </form>

        <div class="mt-6 text-center">
          <NuxtLink to="/" class="text-white/70 hover:text-white text-sm">
            ← Back to Home
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useCognitoAuth } from '~/composables/useCognitoAuth';

const { login, register, confirmSignup, resendCode } = useCognitoAuth();

const email = ref('');
const username = ref('');
const password = ref('');
const confirmationCode = ref('');
const isLoading = ref(false);
const message = ref('');
const isSuccess = ref(false);
const showPassword = ref(false);
const isRegisterMode = ref(false);
const showConfirmation = ref(false);
const pendingUsername = ref('');

const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value;
};

const toggleMode = () => {
  isRegisterMode.value = !isRegisterMode.value;
  message.value = '';
};

const handleSubmit = async () => {
  isLoading.value = true;
  message.value = '';
  isSuccess.value = false;

  try {
    if (isRegisterMode.value) {
      const result = await register(username.value, email.value, password.value);
      
      if (result.success) {
        pendingUsername.value = username.value;
        showConfirmation.value = true;
        message.value = result.message || 'Check your email for verification code';
        isSuccess.value = true;
      } else {
        message.value = result.error || 'Registration failed';
      }
    } else {
      const result = await login(email.value, password.value);
      
      if (result.success) {
        message.value = 'Login successful!';
        isSuccess.value = true;
        
        // Store token for backend API calls
        if (process.client) {
          localStorage.setItem('auth_token', result.token || '');
          localStorage.setItem('cognito_access_token', result.accessToken || '');
        }
        
        // Redirect to home
        setTimeout(() => {
          navigateTo('/');
        }, 1000);
      } else {
        message.value = result.error || 'Login failed';
      }
    }
  } finally {
    isLoading.value = false;
  }
};

const handleConfirmation = async () => {
  isLoading.value = true;
  message.value = '';
  isSuccess.value = false;

  try {
    const result = await confirmSignup(pendingUsername.value, confirmationCode.value);
    
    if (result.success) {
      message.value = 'Email verified! You can now sign in.';
      isSuccess.value = true;
      
      setTimeout(() => {
        showConfirmation.value = false;
        isRegisterMode.value = false;
        confirmationCode.value = '';
        pendingUsername.value = '';
      }, 2000);
    } else {
      message.value = result.error || 'Verification failed';
    }
  } finally {
    isLoading.value = false;
  }
};

const handleResendCode = async () => {
  isLoading.value = true;
  const result = await resendCode(pendingUsername.value);
  message.value = result.message || result.error || '';
  isSuccess.value = result.success;
  isLoading.value = false;
};
</script>
