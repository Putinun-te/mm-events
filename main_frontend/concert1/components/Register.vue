<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { register } from '~/server/register/register';

const router = useRouter();
const username = ref('');
const email = ref('');
const password = ref('');
const isLoading = ref(false);
const message = ref('');
const isSuccess = ref(false);

const handleSubmit = async () => {
  if (!username.value || !email.value || !password.value) {
    message.value = 'Please fill in all fields';
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
    if (res.token) {
      message.value = `Registration successful! Welcome ${res.username}!`;
      isSuccess.value = true;
      localStorage.setItem('jwt_token', res.token);
      localStorage.setItem('user_email', res.email);
      localStorage.setItem('username', res.username);
      username.value = '';
      email.value = '';
      password.value = '';
      // Redirect after short delay (skip during Cypress tests)
      if (!(globalThis as any).Cypress) {
        setTimeout(() => {
          router.push('/LoginPage');
        }, 800);
      }
    } else if (res.message) {
      message.value = res.message;
      isSuccess.value = false;
    }
  } catch (err: any) {
    message.value = err?.response?.data?.message || 'Registration failed!';
    isSuccess.value = false;
  } finally {
    isLoading.value = false;
  }
};
</script>
<template>
  <div class="flex items-center justify-center" data-test="register-container">
    <form @submit.prevent="handleSubmit" data-test="register-form">
      <div class="bg-white w-96 p-6 rounded shadow-sm">
        <div class="flex items-center justify-center mb-4">
          <img src="~/assets/img/apple.jpg" class="h-32" />
        </div>
        <div v-if="message" :class="['px-3 py-2 rounded mb-4 text-center', isSuccess ? 'bg-green-500 text-white' : 'bg-red-500 text-white']">
          <p>{{ message }}</p>
        </div>
        <label class="text-grey-700">Username</label>
        <input data-test="register-username" v-model="username" type="text" placeholder="Enter your username" class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4" :disabled="isLoading" />
        <label class="text-grey-700">Email</label>
        <input data-test="register-email" v-model="email" type="email" placeholder="Enter your email" class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4" :disabled="isLoading" />
        <label class="text-grey-700">Password</label>
        <input data-test="register-password" v-model="password" type="password" placeholder="Enter your password" class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4" :disabled="isLoading" />
        <button data-test="register-submit" type="submit" :disabled="isLoading" :class="['w-full text-gray-100 py-2 rounded transition-colors', isLoading ? 'bg-gray-400 cursor-not-allowed' : 'bg-blue-500 hover:bg-blue-600']">
          {{ isLoading ? 'Registering...' : 'Register' }}
        </button>
      </div>
    </form>
  </div>
</template>
