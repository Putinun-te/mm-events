<script setup lang="ts">
// v2.1.0 - Explicit import for static build
import { ref, onMounted } from "vue";
import { useAuth } from "~/composables/useAuth";
import { useApi } from "../../composables/useApi";

const { saveAuth, loadFromStorage, shouldCompleteProfile } = useAuth()

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)
const showPassword = ref(false)

const togglePasswordVisibility = () => {
  showPassword.value = !showPassword.value
}

onMounted(() => {
  if (process.client) {
    loadFromStorage()
    const remembered = localStorage.getItem('remember_me') === 'true'
    if (remembered) {
      rememberMe.value = true
      const savedEmail = localStorage.getItem('user_email') || ''
      if (savedEmail) email.value = savedEmail
    }
  }
})

const handleSubmit = async () => {
  if (!email.value || !password.value) {
    message.value = "Please fill in all fields";
    isSuccess.value = false;
    return;
  }

  isLoading.value = true;
  message.value = '';

  try {
    const { apiFetch } = useApi()
    const res: any = await apiFetch('/api/auth/login', {
      method: 'POST',
      body: { usernameOrEmail: email.value, password: password.value }
    })

    if (res?.token) {
      message.value = `Login successful! Welcome back ${res.username}!`;
      isSuccess.value = true;

      if (process.client) {
        saveAuth({ token: res.token, email: res.email, username: res.username }, rememberMe.value)
      }

      password.value = ''

      // Redirect after successful login
      if (shouldCompleteProfile()) {
        await navigateTo('/AccountPage')
      } else {
        await navigateTo('/')  // Redirect to home page
      }
    } else if (res?.message) {
      message.value = res.message;
      isSuccess.value = false;
    }
  } catch (err: any) {
    console.error("Login error:", err);
    message.value = err?.data?.message || err?.response?.data?.message || err?.message || "Login failed!";
    isSuccess.value = false;
  } finally {
    isLoading.value = false;
  }
};


</script>
<template>
  <div class="flex items-center justify-center h-screen">
    <form @submit.prevent="handleSubmit">
      <div class="bg-white w-full max-w-md p-8 rounded-xl shadow-lg border border-gray-200">
        <div class="text-center mb-8">
          <h2 class="text-2xl font-bold text-gray-800">Login</h2>
          <p class="text-gray-500 mt-2">Welcome! So good to have you back!</p>
        </div>
        <div class="space-y-5">
          <div>
            <div v-if="message" :class="[
              'px-3 py-2 rounded mb-4 text-center',
              isSuccess ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
              ]">
                <p>{{ message }}</p>
            </div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Username or Email</label>
            <input 
              v-model="email" 
              type="text" 
              id="email" 
              placeholder="username or email@example.com" 
              class="w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
              :disabled="isLoading"
              />
          </div>
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <div class="relative">
              <input 
                v-model="password" 
                :type="showPassword ? 'text' : 'password'"
                id="password" 
                placeholder="Password" 
                class="w-full py-2 px-3 pr-10 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
                :disabled="isLoading"
              />
              <button
                type="button"
                @click="togglePasswordVisibility"
                class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                :disabled="isLoading"
              >
                <svg v-if="!showPassword" class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                <svg v-else class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                </svg>
              </button>
            </div>
          </div>
        </div>
        
        <div class="flex items-start mt-6">
          <div class="flex items-center h-5">
            <input
              v-model="rememberMe"
              id="rememberMe" 
              type="checkbox" 
              class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
            />
          </div>
          <div class="ml-3 text-sm">
            <label for="rememberMe" class="font-medium text-gray-700">
              Remember me
            </label>
          </div>
        </div>

        <div class="mt-6">
          <button 
            type="submit" 
            class="w-full flex justify-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
          >
            Login
          </button>
        </div>
        
        <p class="mt-8 text-center text-sm text-gray-600">
          Create account
          <NuxtLink to="/RegisterPage" class="font-medium text-indigo-600 hover:text-indigo-500 hover:underline">
            Register
          </NuxtLink>
        </p>
      </div>
    </form>
  </div>
</template>