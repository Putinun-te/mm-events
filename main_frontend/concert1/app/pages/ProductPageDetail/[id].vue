<template>
  <div class="product-detail-page">
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div v-if="loading" class="text-center py-12">
        <p class="text-gray-500">Loading product details...</p>
      </div>

      <div v-else-if="product" class="grid grid-cols-1 lg:grid-cols-2 gap-12">
        <!-- Product Image -->
        <div class="aspect-square bg-gray-200 rounded-lg overflow-hidden">
          <img 
            :src="product.image || '/img/product-placeholder.jpg'" 
            :alt="product.title"
            class="w-full h-full object-cover"
          />
        </div>

        <!-- Product Details -->
        <div>
          <h1 class="text-4xl font-bold text-gray-900 mb-4">{{ product.title }}</h1>
          <p class="text-gray-600 text-lg mb-6">{{ product.description }}</p>
          
          <div class="mb-6">
            <span class="text-3xl font-bold text-green-600">${{ product.price }}</span>
          </div>

          <div class="space-y-4 mb-8">
            <div class="flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span class="text-gray-700">{{ product.location || 'Location TBA' }}</span>
            </div>
            <div class="flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span class="text-gray-700">{{ product.date || 'Date TBA' }}</span>
            </div>
          </div>

          <div class="flex gap-4">
            <button 
              @click="addToCart"
              class="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold"
            >
              Add to Cart
            </button>
            <button 
              @click="buyNow"
              class="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-semibold"
            >
              Buy Now
            </button>
          </div>
        </div>
      </div>

      <div v-else class="text-center py-12">
        <p class="text-gray-500">Product not found</p>
        <NuxtLink to="/product-page" class="text-blue-600 hover:underline mt-4 inline-block">
          Back to Products
        </NuxtLink>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from '~/composables/useToast'

const route = useRoute()
const router = useRouter()
const { success } = useToast()

const product = ref<any>(null)
const loading = ref(true)

onMounted(async () => {
  const id = route.params.id
  
  // Mock product data for testing
  await new Promise(resolve => setTimeout(resolve, 500))
  
  product.value = {
    id,
    title: `Product ${id}`,
    description: 'This is a detailed description of the product.',
    price: 99.99,
    location: 'Bangkok, Thailand',
    date: 'December 25, 2025',
    image: ''
  }
  
  loading.value = false
})

const addToCart = () => {
  success('Added to cart!')
}

const buyNow = () => {
  success('Proceeding to checkout...')
  router.push('/checkout')
}
</script>
