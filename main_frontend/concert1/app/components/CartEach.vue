<template>
  <div class="cart-each-item bg-white rounded-lg shadow p-4 mb-4">
    <div class="flex items-center gap-4">
      <div class="flex-1">
        <h3 class="font-semibold text-lg">Yout items</h3>
        <p class="text-gray-600 text-sm">Item description</p>
      </div>
      <div class="flex items-center gap-3">
        <input 
          v-model="test"
          type="number" 
          min="1"
          class="w-20 px-3 py-2 bg-white border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button class="text-red-600 hover:text-red-700">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const test = ref(1)
</script>
