<script setup lang="ts">
import { ref } from 'vue';
const pages = ref([
    { text: 'Login', value: 'login'},
    { text: 'Register', value: 'register'}
])

let show = ref<boolean>(false)
let show2 = ref<boolean>(false)


function click () {
    show.value = !show.value
    // console.log(show.value)
}

function click2 () {
    show2.value = !show2.value
    // console.log(show.value)
}
</script>

<template>
    <h1>this is home</h1>
    <h2>Carousel Section</h2>
    <button>
        <NuxtLink to="/ProductPage" class="text-red-500"> go to product</NuxtLink>
        <NuxtLink to="/ProductPageDetail" class="text-blue-500"> go to product details</NuxtLink>
    </button>
    <div class="pt-20"></div>
    <button class="pl-5 text-red-500 bg-amber-200 pointer cursor-pointer" @click="click">Login</button>
    <div v-if=show>
        <Login />
    </div>
    
    <button class="pl-5 text-red-500 bg-gray-200 pointer cursor-pointer" @click="click2">Register</button>
    <div v-if=show2>
        <Register />
    </div>
</template>