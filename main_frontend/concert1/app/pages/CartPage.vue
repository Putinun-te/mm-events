<template>
  <div class="cart-page">
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Shopping Cart</h1>
      
      <div v-if="cartItems.length === 0" class="text-center py-12">
        <EmptyState 
          title="Your cart is empty"
          message="Start adding some tickets to your cart!"
        />
        <NuxtLink 
          to="/product-page"
          class="inline-block mt-6 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          Browse Events
        </NuxtLink>
      </div>

      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Cart Items -->
        <div class="lg:col-span-2 space-y-4">
          <div 
            v-for="item in cartItems" 
            :key="item.id"
            class="bg-white rounded-lg shadow p-6"
          >
            <div class="flex items-center gap-4">
              <img 
                :src="item.image || '/img/event-placeholder.jpg'" 
                :alt="item.title"
                class="w-24 h-24 object-cover rounded"
              />
              <div class="flex-1">
                <h3 class="text-lg font-semibold">{{ item.title }}</h3>
                <p class="text-gray-600">{{ item.date }}</p>
                <p class="text-gray-600">{{ item.location }}</p>
              </div>
              <div class="text-right">
                <p class="text-xl font-bold text-green-600">${{ item.price }}</p>
                <input 
                  v-model.number="item.quantity"
                  type="number"
                  min="1"
                  class="w-20 mt-2 px-2 py-1 border border-gray-300 rounded"
                />
              </div>
              <button 
                @click="removeItem(item.id)"
                class="text-red-600 hover:text-red-700"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Cart Summary -->
        <div class="lg:col-span-1">
          <div class="bg-white rounded-lg shadow p-6 sticky top-4">
            <h2 class="text-xl font-bold mb-4">Order Summary</h2>
            <div class="space-y-3">
              <div class="flex justify-between">
                <span class="text-gray-600">Subtotal</span>
                <span class="font-semibold">${{ subtotal }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Tax</span>
                <span class="font-semibold">${{ tax }}</span>
              </div>
              <div class="border-t pt-3 flex justify-between">
                <span class="text-lg font-bold">Total</span>
                <span class="text-lg font-bold text-green-600">${{ total }}</span>
              </div>
            </div>
            <button 
              @click="handleCheckout"
              class="w-full mt-6 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold"
            >
              Proceed to Checkout
            </button>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from '~/composables/useToast'

const router = useRouter()
const { success } = useToast()

const cartItems = ref<any[]>([])

const subtotal = computed(() => {
  return cartItems.value.reduce((sum, item) => sum + (item.price * item.quantity), 0).toFixed(2)
})

const tax = computed(() => {
  return (parseFloat(subtotal.value) * 0.1).toFixed(2)
})

const total = computed(() => {
  return (parseFloat(subtotal.value) + parseFloat(tax.value)).toFixed(2)
})

const removeItem = (id: number) => {
  cartItems.value = cartItems.value.filter(item => item.id !== id)
}

const handleCheckout = () => {
  success('Proceeding to checkout...')
  router.push('/checkout')
}
</script>
