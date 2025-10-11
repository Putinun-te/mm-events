<script setup lang="ts">
import { ref,reactive } from 'vue'
import { registerCheck } from '~~/server/api/register/registerCheck'

// let userLst = reactive([])
type user = {
    name: string,
    email: string,
    password: string
}

let userLst = reactive<user[]>([])

async function fetchRegisterCheck() {
    try {
        const users = await registerCheck();
        console.log(users);
        userLst.push(...users)
    }   catch (e) {
        console.log(e)
    } 
}

fetchRegisterCheck()
</script>

<template>

<h1>{{ userLst }}</h1>

</template>