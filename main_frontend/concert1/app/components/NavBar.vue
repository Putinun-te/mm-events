<script setup lang="ts">
const pages = ref([
    { text: 'Mapping', value: 'MapTestingPage'},
    { text: 'Homepage', value: '/'},
    { text: 'About us', value:'AboutUS'}
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
        </div>
    </nav>
</template>