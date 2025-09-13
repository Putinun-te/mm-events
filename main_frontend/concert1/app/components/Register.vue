<script setup lang="ts">
import { ref } from "vue";
import { register } from "~~/server/register/register";

const username = ref('')
const email = ref('')
const password = ref('')
const isLoading = ref(false)
const message = ref('')
const isSuccess = ref(false)

const handleSubmit = async () => {
  if (!username.value || !email.value || !password.value) {
    message.value = "Please fill in all fields";
    isSuccess.value = false;
    return;
  }

  isLoading.value = true;
  message.value = '';

  try {
    const res = await register({
      username: username.value,
      email: email.value,
      password: password.value,
    });
    console.log("Success:", res);
    
    if (res.token) {
      message.value = `Registration successful! Welcome ${res.username}!`;
      isSuccess.value = true;
      // Store token in localStorage
      localStorage.setItem('jwt_token', res.token);
      localStorage.setItem('user_email', res.email);
      localStorage.setItem('username', res.username);
      
      // Clear form
      username.value = '';
      email.value = '';
      password.value = '';
    } else if (res.message) {
      message.value = res.message;
      isSuccess.value = false;
    }
  } catch (err: any) {
    console.error(err);
    message.value = err.response?.data?.message || "Registration failed!";
    isSuccess.value = false;
  } finally {
    isLoading.value = false;
  }
};

</script>
<template>
    <div class="flex items-center justify-center h-screen">
        <form @submit.prevent="handleSubmit">
            <div class="bg-white w-96 p-6 rounded shadow-sm">
                <div class="flex items-center justify-center mb-4">
                    <img src="~/assets/img/apple.jpg" class="h-32"/>
                </div>
                
                <!-- Success/Error Message -->
                <div v-if="message" :class="[
                  'px-3 py-2 rounded mb-4 text-center',
                  isSuccess ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
                ]">
                    <p>{{ message }}</p>
                </div>
                
                <label class="text-grey-700">Username</label>
                <input 
                  v-model="username" 
                  type="text"
                  placeholder="Enter your username"
                  class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4"
                  :disabled="isLoading"
                />
                <label class="text-grey-700">Email</label>
                <input 
                  v-model="email" 
                  type="email"
                  placeholder="Enter your email"
                  class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4"
                  :disabled="isLoading"
                />
                <label class="text-grey-700">Password</label>
                <input 
                  v-model="password" 
                  type="password"
                  placeholder="Enter your password"
                  class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4"
                  :disabled="isLoading"
                />
                <button 
                  type="submit" 
                  :disabled="isLoading"
                  :class="[
                    'w-full text-gray-100 py-2 rounded transition-colors',
                    isLoading ? 'bg-gray-400 cursor-not-allowed' : 'bg-blue-500 hover:bg-blue-600'
                  ]"
                >
                  {{ isLoading ? 'Registering...' : 'Register' }}
                </button>
            </div>
        </form>
    </div>
</template>