<script setup lang="ts">
import { ref } from 'vue'

const email = ref('')
const isSubscribing = ref(false)
const subscribeMessage = ref('')
const currentYear = new Date().getFullYear()

const handleNewsletterSignup = async () => {
  if (!email.value || !email.value.includes('@')) {
    subscribeMessage.value = 'Please enter a valid email address'
    return
  }

  isSubscribing.value = true
  subscribeMessage.value = ''

  try {
    await new Promise(resolve => setTimeout(resolve, 1500))
    subscribeMessage.value = '✅ Successfully subscribed to our newsletter!'
    email.value = ''
  } catch (error) {
    subscribeMessage.value = '❌ Failed to subscribe. Please try again.'
  } finally {
    isSubscribing.value = false
  }
}

const footerLinks = {
  company: [
    { name: 'About Us', url: '/concert/about' },
    { name: 'Careers', url: '/concert/careers' },
    { name: 'Partnerships', url: '/concert/partnerships' },
    { name: 'Press & Media', url: '/concert/press' }
  ],
  events: [
    { name: 'Browse Events', url: '/concert/ProductPage' },
    { name: 'Create Event', url: '/concert/CreateEventPage' },
    { name: 'Event Categories', url: '/concert/ProductPage?category=all' },
    { name: 'Featured Events', url: '/concert/ProductPage#featured' }
  ],
  support: [
    { name: 'Help Center', url: '/concert/help' },
    { name: 'FAQ', url: '/concert/faq' },
    { name: 'Contact Us', url: '/concert/contact' },
    { name: 'Accessibility', url: '/concert/accessibility' }
  ],
  legal: [
    { name: 'Privacy Policy', url: '/concert/privacy' },
    { name: 'Terms of Service', url: '/concert/terms' },
    { name: 'Cookie Policy', url: '/concert/cookies' },
    { name: 'Data Protection', url: '/concert/data-protection' }
  ]
}

const socialLinks = [
  { name: 'Facebook', icon: '📘', url: 'https://facebook.com' },
  { name: 'Twitter', icon: '🐦', url: 'https://twitter.com' },
  { name: 'Instagram', icon: '📸', url: 'https://instagram.com' },
  { name: 'LinkedIn', icon: '💼', url: 'https://linkedin.com' },
  { name: 'YouTube', icon: '📹', url: 'https://youtube.com' }
]
</script>

<template>
  <footer class="bg-gradient-to-br from-gray-900 via-purple-900 to-indigo-900 text-white">
    <!-- Newsletter Section -->
    <div class="border-b border-purple-700/50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="flex flex-col md:flex-row items-center justify-between gap-6">
          <div class="text-center md:text-left">
            <h3 class="text-2xl font-bold mb-2">Stay Updated</h3>
            <p class="text-purple-200">Subscribe to our newsletter for exclusive event updates and offers</p>
          </div>
          <div class="w-full md:w-auto md:min-w-[400px]">
            <form @submit.prevent="handleNewsletterSignup" class="flex gap-2">
              <input v-model="email" type="email" placeholder="Enter your email" class="flex-1 px-4 py-3 rounded-lg bg-white/10 backdrop-blur-sm border border-purple-400/30 text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-pink-500 transition-all" required />
              <button type="submit" :disabled="isSubscribing" class="px-6 py-3 bg-gradient-to-r from-pink-600 to-purple-600 hover:from-pink-700 hover:to-purple-700 rounded-lg font-semibold transition-all disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap">
                {{ isSubscribing ? '...' : 'Subscribe' }}
              </button>
            </form>
            <p v-if="subscribeMessage" :class="subscribeMessage.includes('✅') ? 'text-green-400' : 'text-red-400'" class="mt-2 text-sm">
              {{ subscribeMessage }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Footer Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8">
        <!-- Brand Section -->
        <div class="lg:col-span-1">
          <div class="flex items-center gap-2 mb-4">
            <span class="text-4xl">🎪</span>
            <span class="text-2xl font-bold bg-gradient-to-r from-pink-400 to-purple-400 bg-clip-text text-transparent">EventHub</span>
          </div>
          <p class="text-purple-200 mb-6">Discover and register for amazing events around the world. Connect with people who share your interests.</p>
          <div class="flex gap-3">
            <a v-for="social in socialLinks" :key="social.name" :href="social.url" target="_blank" rel="noopener noreferrer" :aria-label="social.name" class="w-10 h-10 flex items-center justify-center bg-white/10 hover:bg-white/20 rounded-full transition-all text-xl">
              {{ social.icon }}
            </a>
          </div>
        </div>

        <!-- Company Links -->
        <div>
          <h4 class="text-lg font-bold mb-4 text-purple-300">Company</h4>
          <ul class="space-y-2">
            <li v-for="link in footerLinks.company" :key="link.name">
              <NuxtLink :to="link.url" class="text-purple-200 hover:text-white transition-colors">
                {{ link.name }}
              </NuxtLink>
            </li>
          </ul>
        </div>

        <!-- Events Links -->
        <div>
          <h4 class="text-lg font-bold mb-4 text-purple-300">Events</h4>
          <ul class="space-y-2">
            <li v-for="link in footerLinks.events" :key="link.name">
              <NuxtLink :to="link.url" class="text-purple-200 hover:text-white transition-colors">
                {{ link.name }}
              </NuxtLink>
            </li>
          </ul>
        </div>

        <!-- Support Links -->
        <div>
          <h4 class="text-lg font-bold mb-4 text-purple-300">Support</h4>
          <ul class="space-y-2">
            <li v-for="link in footerLinks.support" :key="link.name">
              <NuxtLink :to="link.url" class="text-purple-200 hover:text-white transition-colors">
                {{ link.name }}
              </NuxtLink>
            </li>
          </ul>
        </div>

        <!-- Legal Links -->
        <div>
          <h4 class="text-lg font-bold mb-4 text-purple-300">Legal</h4>
          <ul class="space-y-2">
            <li v-for="link in footerLinks.legal" :key="link.name">
              <NuxtLink :to="link.url" class="text-purple-200 hover:text-white transition-colors">
                {{ link.name }}
              </NuxtLink>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Bottom Bar -->
    <div class="border-t border-purple-700/50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-purple-300">
          <p>© {{ currentYear }} EventHub. All rights reserved.</p>
          <div class="flex items-center gap-6">
            <span>🌍 English</span>
            <span>💳 Secure Payments</span>
            <span>🔒 SSL Encrypted</span>
          </div>
        </div>
      </div>
    </div>
  </footer>
</template>
