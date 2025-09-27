<script setup lang="ts">
import { ref } from 'vue';
import RegisterCheck from './RegisterCheck.vue';
import DatabaseInfo from '~/components/DatabaseInfo.vue';
import Login from '~/components/Login.vue';
import Register from '~/components/Register.vue';

// Always show forms (removed toggles for test stability)
const showAuth = ref(true);
const showDb = ref(false);
function toggleDb(){ showDb.value = !showDb.value }
</script>

<template>
  <h1>this is home</h1>
  <h2>Carousel Section</h2>
  <button>
    <NuxtLink to="/ProductPage" class="text-red-500"> go to product</NuxtLink>
    <NuxtLink to="/ProductPageDetail" class="text-blue-500"> go to product details</NuxtLink>
  </button>
  <div class="pt-20" />
  <div data-test="auth-section" class="flex flex-col gap-8">
    <div data-test="register-wrapper">
      <Register />
    </div>
    <div data-test="login-wrapper">
      <Login />
    </div>
  </div>
  <button type="button" class="pl-5 text-red-500 bg-gray-200" @click="toggleDb">check database</button>
  <div v-if="showDb">
    <DatabaseInfo />
  </div>
</template>