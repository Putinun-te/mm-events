<script setup lang="ts">
import { ref } from "vue";
import { login } from "~~/server/api/login/login";

const email = ref('')
const password = ref('')
const term = ref(false)
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)


// const handleSubmit = () => {
//   console.log("Email:", email.value);
//   console.log("Password:", password.value);
// };

console.log(term)

const handleSubmit = async () => {
  if (!email.value || !password.value) {
    message.value = "Please fill in all fields";
    isSuccess.value = false;
    return;
  }

  isLoading.value = true;
  message.value = '';

  try {
    const res = await login({
      usernameOrEmail: email.value,
      password: password.value,
    });
    console.log("Login Success:", res);
    
    if (res.token) {
      message.value = `Login successful! Welcome back ${res.username}!`;
      isSuccess.value = true;
      // Store token in localStorage
      localStorage.setItem('jwt_token', res.token);
      localStorage.setItem('user_email', res.email);
      localStorage.setItem('username', res.username);
      
      // Clear form
      email.value = '';
      password.value = '';
      
      // Redirect or update UI as needed
      setTimeout(() => {
        // You can navigate to dashboard or home page here
        console.log("Redirecting to dashboard...");
        
      }, 2000);
    } else if (res.message) {
      message.value = res.message;
      isSuccess.value = false;
    }
  } catch (err: any) {
    console.error("Login error:", err);
    message.value = err.response?.data?.message || "Login failed!";
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
              v-model="term"
              id="terms" 
              type="checkbox" 
              class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
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
          >
            Register
          </button>
        </div>
        
        <p class="mt-8 text-center text-sm text-gray-600">
          Create account
          <a href="#" class="font-medium text-indigo-600 hover:text-indigo-500 hover:underline">
            Register
          </a>
        </p>
      </div>
    </form>
  </div>
</template>