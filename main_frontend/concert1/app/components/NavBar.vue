<script setup lang="ts">
import { ref } from 'vue';
import Login from './Login.vue';

let user = ref('')

const pages = ref([
    { text: 'Home', value: '/'},
    { text: 'Mapping', value: 'MapTestingPage'},
    { text: 'Account', value: 'AccountPage'},
    { text: 'Contact', value:''}
])

const pagess = ref([
    { text: 'Create Event', value: 'CreateEventPage'},
    { text: 'Cart', value: 'CartPage'},
    { text: '', value: 'AccountPage'},
    { text: 'Login', value: 'LoginPage'},
    { text: 'Register', value: 'RegisterPage'},
    { text: 'Profile', value:'AboutUS'}
])

</script>

<template>
    <nav class="bg-black text-white fixed w-full z-20 top-0 start-0 border-b">
        <div class="max-w-5xl flex flex-wrap items-center justify-between mx-auto p-4">
            <NuxtLink to="/">
                <span class="self-center text-2xl font-semibold whitespace-nowrap dark:text-white">MM concerts</span>
            </NuxtLink>
            <ul class="flex flex-row">
                <li v-for="page in pages" :key="page.value">
                    <NuxtLink :to="`${page.value}`" :class="[' hover:text-blue-400 p-3']">{{ page.text }}</NuxtLink>
                </li>
            </ul>

            <ul class="flex flex-row">
                <li v-for="page in pagess" :key="page.value">
                    <NuxtLink :to="`${page.value}`" :class="[' hover:text-blue-400 p-3']">{{ page.text }}</NuxtLink>
                </li>
            </ul>
            <!-- for account and when login complete-->
            <!-- <ul class="flex flex-row">
                <NuxtLink to="/ProductPageDetail" :class="[' hover:text-blue-400 p-3']"></NuxtLink>
            </ul>                       -->
        </div>
    </nav>
</template>