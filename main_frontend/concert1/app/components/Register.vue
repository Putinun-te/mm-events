<script setup lang="ts">
import { ref } from "vue";
import { register } from "~~/server/register/register";

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
</template>