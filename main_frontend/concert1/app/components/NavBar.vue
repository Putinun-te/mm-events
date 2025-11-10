<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'

const router = useRouter()
const route = useRoute()
const { loadFromStorage, isLoggedIn, clearAuth, user } = useAuth()
const { success } = useToast()
const showLogoutModal = ref(false)

const isMenuOpen = ref(false)
const showDropdown = ref(false)

const pages = ref([
    { text: 'Account', value: '/AccountPage'}
])

const authPages = ref([
    { text: 'All Events', value: '/product-page'},
    { text: 'Create Event', value: '/CreateEventPage'},
    { text: 'Login/Register', value: '/LoginPage'},
])

onMounted(() => {
  loadFromStorage()
  // close mobile menu on desktop resize
  window.addEventListener('resize', onResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', onResize)
})

watch(() => route.fullPath, () => {
  // close menu when navigating
  isMenuOpen.value = false
})

function onResize() {
  if (window.innerWidth >= 768) isMenuOpen.value = false
}

function toggleMenu() {
  isMenuOpen.value = !isMenuOpen.value
}

function handleLogout() {
  showLogoutModal.value = true
}

function confirmLogout() {
  clearAuth()
  localStorage.removeItem('profile_data')
  showLogoutModal.value = false
  success('Logged out successfully', 'Goodbye!')
  router.push('/')
}

function cancelLogout() {
  showLogoutModal.value = false
}
</script>

<template>
  <nav class="bg-black text-white fixed w-full z-20 top-0 left-0 border-b">
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <div class="flex items-center">
          <NuxtLink to="/" class="flex items-center">
            <span class="text-2xl font-semibold whitespace-nowrap">MM concerts</span>
          </NuxtLink>
        </div>

        <!-- Desktop Links -->
        <div class="hidden md:flex md:items-center md:space-x-4">
          <ul class="flex items-center space-x-2">
            <li v-if="!isLoggedIn" v-for="page in authPages" :key="page.value">
              <NuxtLink :to="page.value" class="px-3 py-2 rounded hover:text-blue-400 transition">
                {{ page.text }}
              </NuxtLink>
            </li>

            <li v-if="isLoggedIn">
              <NuxtLink to="/CreateEventPage" class="px-3 py-2 rounded hover:text-blue-400 transition">Create Event</NuxtLink>
            </li>

            <li v-if="isLoggedIn" class="relative">
              <button @click="showDropdown = !showDropdown" class="flex items-center gap-2 px-3 py-2 rounded hover:bg-white/10 transition">
                <img v-if="user?.profilePhoto" :src="user.profilePhoto" class="w-8 h-8 rounded-full object-cover" />
                <div v-else class="w-8 h-8 rounded-full bg-violet-600 flex items-center justify-center text-sm font-bold">
                  {{ user?.name?.charAt(0)?.toUpperCase() || 'U' }}
                </div>
                <span class="text-sm">{{ user?.name }}</span>
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                </svg>
              </button>
              
              <div v-if="showDropdown" @click="showDropdown = false" class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg py-1 text-gray-800">
                <NuxtLink to="/MyBookingsPage" class="block px-4 py-2 hover:bg-gray-100">My Bookings</NuxtLink>
                <NuxtLink to="/MyEventsPage" class="block px-4 py-2 hover:bg-gray-100">My Events</NuxtLink>
                <NuxtLink to="/AccountPage" class="block px-4 py-2 hover:bg-gray-100">Account Settings</NuxtLink>
                <hr class="my-1">
                <button @click="handleLogout" class="w-full text-left px-4 py-2 hover:bg-red-50 text-red-600">Logout</button>
              </div>
            </li>
          </ul>
        </div>

        <!-- Mobile hamburger -->
        <div class="md:hidden flex items-center">
          <button
            @click="toggleMenu"
            aria-label="Toggle menu"
            :aria-expanded="isMenuOpen"
            class="inline-flex items-center justify-center p-2 rounded-md hover:bg-white/10 focus:outline-none focus:ring-2 focus:ring-white"
          >
            <svg v-if="!isMenuOpen" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
            </svg>
            <svg v-else class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Mobile menu panel -->
    <transition name="fade">
      <div v-show="isMenuOpen" class="md:hidden bg-black/95 border-t">
        <div class="px-4 pt-4 pb-6 space-y-2">
          <ul class="flex flex-col">
            <li v-if="!isLoggedIn" v-for="page in authPages" :key="page.value">
              <NuxtLink
                :to="page.value"
                class="block px-3 py-2 rounded text-white hover:bg-white/5"
                @click="isMenuOpen = false"
              >
                {{ page.text }}
              </NuxtLink>
            </li>

            <li v-if="isLoggedIn">
              <NuxtLink to="/CreateEventPage" class="block px-3 py-2 rounded text-white hover:bg-white/5" @click="isMenuOpen = false">Create Event</NuxtLink>
            </li>
            <li v-if="isLoggedIn">
              <NuxtLink to="/MyBookingsPage" class="block px-3 py-2 rounded text-white hover:bg-white/5" @click="isMenuOpen = false">My Bookings</NuxtLink>
            </li>
            <li v-if="isLoggedIn">
              <NuxtLink to="/MyEventsPage" class="block px-3 py-2 rounded text-white hover:bg-white/5" @click="isMenuOpen = false">My Events</NuxtLink>
            </li>
            <li v-if="isLoggedIn">
              <NuxtLink to="/AccountPage" class="block px-3 py-2 rounded text-white hover:bg-white/5" @click="isMenuOpen = false">Account Settings</NuxtLink>
            </li>
            <li v-if="isLoggedIn">
              <button @click="() => { handleLogout(); isMenuOpen = false }" class="w-full text-left px-3 py-2 rounded bg-red-600 hover:bg-red-700 text-white">Logout</button>
            </li>
          </ul>
        </div>
      </div>
    </transition>

    <!-- Logout Confirmation Modal -->
    <LogoutModal 
      :show="showLogoutModal" 
      @confirm="confirmLogout" 
      @cancel="cancelLogout" 
    />
  </nav>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>