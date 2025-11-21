<template>
  <div class="product-filter-selection bg-white rounded-lg shadow p-4">
    <h3 class="text-lg font-semibold mb-4">Filter Products</h3>
    
    <div class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Category</label>
        <select 
          v-model="selectedCategory"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All Categories</option>
          <option value="concerts">Concerts</option>
          <option value="sports">Sports</option>
          <option value="theater">Theater</option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Price Range</label>
        <select 
          v-model="selectedPriceRange"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All Prices</option>
          <option value="0-50">$0 - $50</option>
          <option value="50-100">$50 - $100</option>
          <option value="100+">$100+</option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">Location</label>
        <input 
          v-model="selectedLocation"
          type="text"
          placeholder="Enter location"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <button 
        @click="applyFilters"
        class="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
      >
        Apply Filters
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const selectedCategory = ref('')
const selectedPriceRange = ref('')
const selectedLocation = ref('')

const applyFilters = () => {
  console.log('Applying filters:', {
    category: selectedCategory.value,
    priceRange: selectedPriceRange.value,
    location: selectedLocation.value
  })
}
</script>
