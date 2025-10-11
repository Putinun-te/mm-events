<script setup lang="ts">
import { ref } from "vue";

const username = ref('')
const email = ref('')
const password = ref('')
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)

const handleSubmit = async () => {
  if (isLoading.value) return;
  message.value = ''
  isSuccess.value = false

  if (!username.value || !email.value || !password.value) {
    message.value = 'Please fill all fields';
    return;
  }
  if (!/.+@.+\..+/.test(email.value)) {
    message.value = 'Please enter a valid email';
    return;
  }
  if (password.value.length < 6) {
    message.value = 'Password must be at least 6 characters';
    return;
  }

  try {
    isLoading.value = true
    const res: any = await $fetch('/api/auth/register', {
      method: 'POST',
      body: {
        username: username.value,
        email: email.value,
        password: password.value,
      }
    })

    if (res?.token || !res?.message) {
      isSuccess.value = true
      message.value = 'Registered successfully! Please login.'
      await navigateTo('/LoginPage')
      return
    }

    message.value = res.message || 'Registration failed!'
  } catch (err: any) {
    console.error('Register error:', err);
    const msg = err?.data?.message || err?.response?.data?.message || err?.message || 'Registration failed!';
    message.value = msg
  } finally {
    isLoading.value = false
  }
};

</script>
<template>
  <div class="flex items-center justify-center h-screen">
    <form @submit.prevent="handleSubmit">
      <div class="bg-white w-full max-w-md p-8 rounded-xl shadow-lg border border-gray-200">
        <div class="text-center mb-8">
          <h2 class="text-2xl font-bold text-gray-800">Create Your Account</h2>
          <p class="text-gray-500 mt-2">Let's get you started!</p>
        </div>

        <div v-if="message" :class="['px-3 py-2 rounded mb-4 text-center', isSuccess ? 'bg-green-500 text-white' : 'bg-red-500 text-white']">
          <p>{{ message }}</p>
        </div>

        <div class="space-y-5">
          <div>
            <label for="username" class="block text-sm font-medium text-gray-700 mb-1">Username</label>
            <input 
              v-model="username" 
              type="text" 
              id="username" 
              placeholder="Enter a username" 
              class="w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
              :disabled="isLoading"
            />
          </div>
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
            <input 
              v-model="email" 
              type="email" 
              id="email" 
              placeholder="you@example.com" 
              class="w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
              :disabled="isLoading"
            />
          </div>
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input 
              v-model="password" 
              type="password" 
              id="password" 
              placeholder="••••••••" 
              class="w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
              :disabled="isLoading"
            />
          </div>
        </div>
        
        <div class="flex items-start mt-6">
          <div class="flex items-center h-5">
            <input 
              id="terms" 
              type="checkbox" 
              class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
              :disabled="isLoading"
            />
          </div>
          <div class="ml-3 text-sm">
            <label for="terms" class="font-medium text-gray-700">
              I agree to the 
              <a href="#" class="text-indigo-600 hover:underline">Terms and Conditions</a>
            </label>
          </div>
        </div>

        <div class="mt-6">
          <button 
            type="submit" 
            class="w-full flex justify-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
            :disabled="isLoading"
          >
            {{ isLoading ? 'Registering...' : 'Register' }}
          </button>
        </div>
        
        <p class="mt-8 text-center text-sm text-gray-600">
          Already have an account? 
          <NuxtLink to="/LoginPage" class="font-medium text-indigo-600 hover:text-indigo-500 hover:underline">
            Log in
          </NuxtLink>
        </p>
      </div>
    </form>
  </div>
</template>