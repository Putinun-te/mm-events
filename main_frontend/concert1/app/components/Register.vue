<script setup lang="ts">
import { ref } from "vue";
import { register } from "~~/server/api/register/register";

const name = ref('')
const email = ref('')
const password = ref('')

// const handleSubmit = () => {
//   console.log("Name:", name.value);
//   console.log("Email:", email.value);
//   console.log("Password:", password.value);
// };

const handleSubmit = async () => {
  try {
    const res = await register({
      name: name.value,
      email: email.value,
      password: password.value,
    });
    console.log("Success:", res);
    alert("Registered successfully!");
  } catch (err) {
    console.error(err);
    alert("Registration failed!");
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
        <div class="space-y-5">
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <input 
              v-model="name" 
              type="text" 
              id="name" 
              placeholder="Enter your full name" 
              class="w-full py-2 px-3 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 transition"
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
            />
          </div>
        </div>
        
        <div class="flex items-start mt-6">
          <div class="flex items-center h-5">
            <input 
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
          Already have an account? 
          <a href="#" class="font-medium text-indigo-600 hover:text-indigo-500 hover:underline">
            Log in
          </a>
        </p>
      </div>
    </form>
  </div>
</template>
<!-- <template>
    <div class="flex items-center justify-center h-screen">
        <form @submit.prevent="handleSubmit">
            <div class="bg-white w-96 p-6 rounded shadow-sm">
                <div class="flex items-center justify-center mb-4">
                    <img src="~/assets/img/apple.jpg" class="h-32"/>
                </div>
                <label class="text-grey-700">Name</label>
                <input v-model="name" class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4"/>
                <label class="text-grey-700">Email</label>
                <input v-model="email" class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4"/>
                <label class="text-grey-700">Password</label>
                <input v-model="password" class="w-full py-2 bg-gray-200 text-grey-500 px-1 outline-none mb-4"/>
                <input class="mb-4" type="checkbox" id="remember"/>
                <label class="text-gray-300" for="remember">Remember</label>
                <button type="submit" class="bg-blue-500 w-full text-gray-100 py-2 rounded hover:bg-blue-500 transition-colors">Register</button>
            </div>
        </form>
    </div>
</template> -->