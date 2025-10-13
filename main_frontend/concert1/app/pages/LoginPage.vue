<script setup lang="ts">
import { ref, onMounted } from "vue"
import { useAuth } from "~/composables/useAuth"

const { saveAuth, loadFromStorage, shouldCompleteProfile } = useAuth()

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)
const showPassword = ref(false)

onMounted(() => {
  if (typeof window !== 'undefined') {
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
    message.value = "Please fill in all fields"
    isSuccess.value = false
    return
  }

  isLoading.value = true
  message.value = ''

  try {
    const res: any = await $fetch('/api/auth/login', {
      method: 'POST',
      body: { usernameOrEmail: email.value, password: password.value }
    })

    if (res?.token) {
      message.value = `Login successful! Welcome back ${res.username}!`
      isSuccess.value = true

      if (typeof window !== 'undefined') {
        saveAuth({ token: res.token, email: res.email, username: res.username }, rememberMe.value)
      }

      password.value = ''

      setTimeout(() => {
        if (shouldCompleteProfile()) {
          navigateTo('/AccountPage')
        } else {
          navigateTo('/ProductPage')
        }
      }, 1000)
    } else if (res?.message) {
      message.value = res.message
      isSuccess.value = false
    }
  } catch (err: any) {
    console.error("Login error:", err)
    message.value = err?.data?.message || err?.response?.data?.message || err?.message || "Login failed!"
    isSuccess.value = false
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 flex items-center justify-center p-4">
    <div class="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden">
      <div class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 px-8 py-10 text-center">
        <div class="text-5xl mb-4">🎪</div>
        <h2 class="text-3xl font-bold text-white">Welcome Back!</h2>
        <p class="text-purple-100 mt-2">Sign in to discover amazing events</p>
      </div>
      
      <form @submit.prevent="handleSubmit" class="p-8">
        <div v-if="message" :class="['px-4 py-3 rounded-lg mb-6 text-center font-medium transition-all', isSuccess ? 'bg-green-50 text-green-800 border border-green-200' : 'bg-red-50 text-red-800 border border-red-200']">
          <p>{{ message }}</p>
        </div>

        <div class="space-y-5">
          <div>
            <label for="email" class="block text-sm font-semibold text-gray-700 mb-2">Email Address</label>
            <input v-model="email" type="text" id="email" placeholder="you@example.com" class="w-full py-3 px-4 bg-gray-50 border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" :disabled="isLoading" />
          </div>

          <div>
            <label for="password" class="block text-sm font-semibold text-gray-700 mb-2">Password</label>
            <div class="relative">
              <input v-model="password" :type="showPassword ? 'text' : 'password'" id="password" placeholder="••••••••" class="w-full py-3 px-4 pr-12 bg-gray-50 border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" :disabled="isLoading" />
              <button type="button" @click="showPassword = !showPassword" class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700 focus:outline-none">
                <span v-if="showPassword">🙈</span>
                <span v-else>👁️</span>
              </button>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-between mt-6">
          <div class="flex items-center">
            <input v-model="rememberMe" id="rememberMe" type="checkbox" class="h-4 w-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500" />
            <label for="rememberMe" class="ml-2 text-sm font-medium text-gray-700">Remember me</label>
          </div>
          <a href="#" class="text-sm font-medium text-purple-600 hover:text-purple-700 hover:underline">Forgot password?</a>
        </div>

        <button type="submit" :disabled="isLoading" class="mt-8 w-full py-3 px-4 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white font-bold rounded-lg shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none">
          <span v-if="isLoading" class="flex items-center justify-center">
            <svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            Signing in...
          </span>
          <span v-else>Sign In</span>
        </button>

        <p class="mt-8 text-center text-sm text-gray-600">
          Don't have an account? 
          <NuxtLink to="/RegisterPage" class="font-semibold text-purple-600 hover:text-purple-700 hover:underline">Create one now</NuxtLink>
        </p>
      </form>
    </div>
  </div>
</template>
