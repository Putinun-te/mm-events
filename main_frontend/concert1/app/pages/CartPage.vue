<script setup lang="ts">
import { ref } from 'vue';

let items = ref(98)
</script>


<template>
    <div class="bg-white rounded shadow-sm">
        <div class="w-full max-w-2xl">
            <div class="p-6 md:p-8">
                <h1 class="text-3xl font-bold text-gray-900">Your Cart</h1>

                <div v-for="i in 5" key="i">
                    <div class="flex justify-between pb-3">
                        <p class="pt-5">items {{ i }}</p>
                        <input
                            v-model="items"
                            class="px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                            type="number" 
                            />
                            <!-- <CartEach /> -->
                    </div>
                </div>
                
            </div>
            <!-- <hr class="flex justify-center items-center border-red-500"> -->
        </div>
        <div class="flex items-center justify-center pb-5">
            <button type="submit"
                class="w-1/2 flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white transition-colors"
                style="background-color: #362e54;" onmouseover="this.style.backgroundColor='#4a3f70'"
                onmouseout="this.style.backgroundColor='#362e54'">Check Out</button>
            
            </div>
    </div>
</template>