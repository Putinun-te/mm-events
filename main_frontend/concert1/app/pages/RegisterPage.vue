<script setup lang="ts">
import { ref } from "vue"

const username = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)
const showPassword = ref(false)
const showConfirmPassword = ref(false)
const agreedToTerms = ref(false)

const passwordStrength = ref(0)

const checkPasswordStrength = () => {
  const pwd = password.value
  let strength = 0
  if (pwd.length >= 8) strength++
  if (pwd.length >= 12) strength++
  if (/[a-z]/.test(pwd) && /[A-Z]/.test(pwd)) strength++
  if (/\d/.test(pwd)) strength++
  if (/[!@#$%^&*(),.?":{}|<>]/.test(pwd)) strength++
  passwordStrength.value = Math.min(strength, 5)
}

const handleSubmit = async () => {
  if (isLoading.value) return
  message.value = ''
  isSuccess.value = false

  if (!username.value || !email.value || !password.value || !confirmPassword.value) {
    message.value = 'Please fill all fields'
    return
  }
  if (!/.+@.+\..+/.test(email.value)) {
    message.value = 'Please enter a valid email'
    return
  }
  if (password.value.length < 6) {
    message.value = 'Password must be at least 6 characters'
    return
  }
  if (password.value !== confirmPassword.value) {
    message.value = 'Passwords do not match'
    return
  }
  if (!agreedToTerms.value) {
    message.value = 'Please agree to the Terms and Conditions'
    return
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
      message.value = 'Account created successfully! Redirecting to login...'
      setTimeout(() => {
        navigateTo('/LoginPage')
      }, 2000)
      return
    }

    message.value = res.message || 'Registration failed!'
  } catch (err: any) {
    console.error('Register error:', err)
    const msg = err?.data?.message || err?.response?.data?.message || err?.message || 'Registration failed!'
    message.value = msg
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-pink-500 via-purple-500 to-indigo-500 flex items-center justify-center p-4">
    <div class="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden">
      <div class="bg-gradient-to-r from-pink-600 via-purple-600 to-indigo-600 px-8 py-10 text-center">
        <div class="text-5xl mb-4">🎉</div>
        <h2 class="text-3xl font-bold text-white">Join Us Today!</h2>
        <p class="text-purple-100 mt-2">Create your account and start exploring</p>
      </div>
      
      <form @submit.prevent="handleSubmit" class="p-8">
        <div v-if="message" :class="['px-4 py-3 rounded-lg mb-6 text-center font-medium transition-all', isSuccess ? 'bg-green-50 text-green-800 border border-green-200' : 'bg-red-50 text-red-800 border border-red-200']">
          <p>{{ message }}</p>
        </div>

        <div class="space-y-5">
          <div>
            <label for="username" class="block text-sm font-semibold text-gray-700 mb-2">Username</label>
            <input v-model="username" type="text" id="username" placeholder="Choose a username" class="w-full py-3 px-4 bg-gray-50 border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" :disabled="isLoading" />
          </div>

          <div>
            <label for="email" class="block text-sm font-semibold text-gray-700 mb-2">Email Address</label>
            <input v-model="email" type="email" id="email" placeholder="you@example.com" class="w-full py-3 px-4 bg-gray-50 border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" :disabled="isLoading" />
          </div>

          <div>
            <label for="password" class="block text-sm font-semibold text-gray-700 mb-2">Password</label>
            <div class="relative">
              <input v-model="password" @input="checkPasswordStrength" :type="showPassword ? 'text' : 'password'" id="password" placeholder="Create a strong password" class="w-full py-3 px-4 pr-12 bg-gray-50 border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" :disabled="isLoading" />
              <button type="button" @click="showPassword = !showPassword" class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700 focus:outline-none">
                <span v-if="showPassword">🙈</span>
                <span v-else>👁️</span>
              </button>
            </div>
            <div v-if="password" class="mt-2">
              <div class="flex gap-1">
                <div v-for="i in 5" :key="i" :class="['h-1 flex-1 rounded-full transition-all', i <= passwordStrength ? (passwordStrength <= 2 ? 'bg-red-500' : passwordStrength <= 3 ? 'bg-yellow-500' : 'bg-green-500') : 'bg-gray-200']"></div>
              </div>
              <p class="text-xs mt-1" :class="{'text-red-600': passwordStrength <= 2, 'text-yellow-600': passwordStrength === 3, 'text-green-600': passwordStrength >= 4}">
                {{ passwordStrength <= 2 ? 'Weak password' : passwordStrength === 3 ? 'Moderate password' : 'Strong password' }}
              </p>
            </div>
          </div>

          <div>
            <label for="confirmPassword" class="block text-sm font-semibold text-gray-700 mb-2">Confirm Password</label>
            <div class="relative">
              <input v-model="confirmPassword" :type="showConfirmPassword ? 'text' : 'password'" id="confirmPassword" placeholder="Confirm your password" class="w-full py-3 px-4 pr-12 bg-gray-50 border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" :disabled="isLoading" />
              <button type="button" @click="showConfirmPassword = !showConfirmPassword" class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700 focus:outline-none">
                <span v-if="showConfirmPassword">🙈</span>
                <span v-else>👁️</span>
              </button>
            </div>
            <p v-if="confirmPassword && password !== confirmPassword" class="text-xs text-red-600 mt-1">Passwords do not match</p>
          </div>
        </div>

        <div class="flex items-start mt-6">
          <div class="flex items-center h-5">
            <input v-model="agreedToTerms" id="terms" type="checkbox" class="h-4 w-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500" :disabled="isLoading" />
          </div>
          <div class="ml-3 text-sm">
            <label for="terms" class="font-medium text-gray-700">
              I agree to the <a href="#" class="text-purple-600 hover:underline">Terms and Conditions</a>
            </label>
          </div>
        </div>

        <button type="submit" :disabled="isLoading || !agreedToTerms" class="mt-8 w-full py-3 px-4 bg-gradient-to-r from-pink-600 via-purple-600 to-indigo-600 text-white font-bold rounded-lg shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none">
          <span v-if="isLoading" class="flex items-center justify-center">
            <svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            Creating account...
          </span>
          <span v-else>Create Account</span>
        </button>

        <p class="mt-8 text-center text-sm text-gray-600">
          Already have an account? 
          <NuxtLink to="/LoginPage" class="font-semibold text-purple-600 hover:text-purple-700 hover:underline">Sign in</NuxtLink>
        </p>
      </form>
    </div>
  </div>
</template>
