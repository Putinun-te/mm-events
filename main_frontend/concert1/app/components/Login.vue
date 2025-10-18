<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useAuth } from "~/composables/useAuth";

const { saveAuth, loadFromStorage, shouldCompleteProfile } = useAuth()

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)

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
    const res: any = await $fetch('/api/auth/login', {
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
            <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
            <input 
              v-model="email" 
              type="text" 
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
              minlength="8"
              id="password"
              placeholder="Password" 
              class="w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
              :disabled="isLoading"
              autocomplete="new-password"
              required 
              />
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
<!-- <style scoped>
input[type="password"]::-ms-reveal,
input[type="password"]::-ms-clear,
input[type="password"]::-webkit-contacts-auto-fill-button,
input[type="password"]::-webkit-credentials-auto-fill-button,
input[type="password"]::-webkit-textfield-decoration-container,
input[type="password"]::-webkit-clear-button,
input[type="password"]::-webkit-inner-spin-button {
  display: none !important;
  appearance: none;
}
</style> -->