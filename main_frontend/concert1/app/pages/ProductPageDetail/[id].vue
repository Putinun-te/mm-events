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
            :src="product.posterUrl || product.image || '/img/product-placeholder.jpg'" 
            :alt="product.title || product.name"
            class="w-full h-full object-cover"
          />
        </div>

        <!-- Product Details -->
        <div>
          <h1 class="text-4xl font-bold text-gray-900 mb-4">{{ product.title || product.name }}</h1>
          <p class="text-gray-600 text-lg mb-6">{{ product.description }}</p>
          
          <div class="mb-6">
            <span class="text-3xl font-bold text-green-600">${{ product.ticketPrice || product.price || 0 }}</span>
          </div>

          <div class="space-y-4 mb-8">
            <div class="flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span class="text-gray-700">{{ product.location || product.city || 'Location TBA' }}</span>
            </div>
            <div v-if="product.startDate || product.datestart" class="flex items-center gap-2">
              <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span class="text-gray-700">{{ formatDateTime(product.startDate || product.datestart) }}</span>
            </div>
            <div v-if="product.category">
              <span class="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">{{ product.category }}</span>
            </div>
            <div v-if="spotsRemaining !== null">
              <p class="text-gray-600">
                <strong>Available:</strong> {{ spotsRemaining }} spots remaining
                <span v-if="product.participantsCount"> ({{ product.participantsCount }} registered)</span>
              </p>
            </div>
          </div>

          <!-- Quantity Controls -->
          <div class="flex items-center gap-4 mb-6">
            <span class="text-gray-700">Quantity:</span>
            <button 
              @click="changeQuantity(-1)"
              class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300"
              :disabled="quantity <= 1"
            >
              -
            </button>
            <span class="text-xl font-semibold">{{ quantity }}</span>
            <button 
              @click="changeQuantity(1)"
              class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300"
              :disabled="quantity >= spotsRemaining"
            >
              +
            </button>
          </div>

          <!-- Total Price -->
          <div class="mb-6">
            <p class="text-2xl font-bold text-green-600">
              Total: ${{ totalPrice }}
            </p>
          </div>

          <div class="flex gap-4">
            <button 
              @click="addToCart"
              :disabled="isFull"
              class="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {{ isFull ? 'Event Full' : 'Add to Cart' }}
            </button>
            <button 
              @click="buyNow"
              :disabled="isFull"
              class="flex-1 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-semibold disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              {{ isFull ? 'Event Full' : 'Buy Now' }}
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
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from '~/composables/useToast'

const route = useRoute()
const router = useRouter()
const { success } = useToast()

const product = ref<any>(null)
const loading = ref(true)
const quantity = ref(1)

const spotsRemaining = computed(() => {
  if (!product.value) return null
  if (!product.value.personLimit || product.value.personLimit === 0) return 999 // Unlimited
  const taken = product.value.participantsCount || 0
  return Math.max(0, product.value.personLimit - taken)
})

const isFull = computed(() => {
  if (!product.value || !product.value.personLimit) return false
  return spotsRemaining.value === 0
})

const totalPrice = computed(() => {
  const price = product.value?.ticketPrice || product.value?.price || 0
  return (price * quantity.value).toFixed(2)
})

onMounted(async () => {
  await loadEventData()
  await loadScript('https://api.longdo.com/map/?key=YOUR_KEY')
})

async function loadEventData() {
  loading.value = true
  const id = route.params.id
  
  try {
    // Try /api/events/json/123 first (primary endpoint)
    product.value = await $fetch(`/api/events/json/${id}`)
  } catch (error) {
    // Fallback to /api/events/123
    try {
      product.value = await $fetch(`/api/events/${id}`)
    } catch (err) {
      console.error('Failed to load event:', err)
      product.value = null
    }
  } finally {
    loading.value = false
  }
}

const formatDateTime = (date: any): string => {
  if (!date) return 'Date TBA'
  
  try {
    // Handle epoch timestamp
    if (typeof date === 'number') {
      return new Date(date * 1000).toLocaleString()
    }
    // Handle ISO string
    return new Date(date).toLocaleString()
  } catch {
    return 'Date TBA'
  }
}

const changeQuantity = (delta: number) => {
  const newQty = quantity.value + delta
  if (newQty >= 1 && newQty <= spotsRemaining.value) {
    quantity.value = newQty
  }
}

const addToCart = () => {
  if (isFull.value) return
  success(`Added ${quantity.value} ticket(s) to cart!`)
}

const buyNow = () => {
  if (isFull.value) return
  success('Proceeding to checkout...')
  router.push('/checkout')
}

const loadScript = (src: string): Promise<void> => {
  return new Promise((resolve, reject) => {
    if (typeof document === 'undefined') {
      resolve()
      return
    }
    
    const script = document.createElement('script')
    script.src = src
    script.onload = () => resolve()
    script.onerror = () => reject(new Error(`Failed to load script: ${src}`))
    document.head.appendChild(script)
  })
}
</script>
