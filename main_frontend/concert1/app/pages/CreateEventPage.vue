<script setup lang="ts">
import { ref } from 'vue'
const { data } = await useFetch(() => `/api/product/data`)

console.log(data.value)
</script>

<template>
  <div class="bg-white rounded shadow-sm py-12 sm:py-16">
    <div class="flex items-center justify-center">
      <form @submit.prevent="handleSubmit" class="w-full max-w-2xl">
        <div class="p-6 md:p-8">
          <h1 class="text-3xl font-bold text-gray-900">Create Event</h1>

          <div class="mt-10">
            <h2 class="text-lg font-semibold leading-7 text-gray-800">Event Picture</h2>
            <div class="mt-4 flex items-center justify-center mb-4">
              <div class="relative w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center text-gray-400">
                <!-- <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg> -->
              </div>
            </div>
          </div>


          <div class="mt-10">
            <h2 class="text-xl font-semibold leading-7 text-gray-800">Event Details</h2>
            <p class="mt-1 text-sm text-gray-500">Our team will carefully consider them and get back to you within 24 hours.</p>
            <div class="mt-6 space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="phone" class="text-sm font-medium text-gray-700">Event Name</label>
                <input v-model="phone" type="text" id="phone" placeholder="Enter Event name" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="address" class="text-sm font-medium text-gray-700">Address</label>
                <input v-model="address" type="text" id="address" placeholder="Enter address" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="city" class="text-sm font-medium text-gray-700">City/Town</label>
                <input v-model = "city" type="text" id="city" placeholder="Enter city" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="country" class="text-sm font-medium text-gray-700">Country</label>
                <input v-model = "country" type="text" id="country" placeholder="Enter country" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="country" class="text-sm font-medium text-gray-700">People</label>
                <input v-model = "p" type="number" id="country" placeholder="Enter Limit People" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>              
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="country" class="text-sm font-medium text-gray-700">Phone Number</label>
                <input v-model = "d" type="tel" id="phone" placeholder="Enter Phone Number" name="phone" pattern="[0-9]{3}-[0-9]{2}-[0-9]{3}" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>                        
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="country" class="text-sm font-medium text-gray-700">Date</label>
                <input v-model = "v" type="date" id="country" placeholder="Enter country" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>              
            </div>
          </div>
          
          <div class="mt-10">
            <button @click="saveProfile"  type="submit" class="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white transition-colors" style="background-color: #362e54;" onmouseover="this.style.backgroundColor='#4a3f70'" onmouseout="this.style.backgroundColor='#362e54'">Send</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
