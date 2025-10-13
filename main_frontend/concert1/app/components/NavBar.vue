<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuth } from '~/composables/useAuth'

const auth = useAuth()
const { isLoggedIn, user } = auth
const isMobileMenuOpen = ref(false)
const isUserMenuOpen = ref(false)

const handleLogout = () => {
  auth.clearAuth()
  if (typeof window !== 'undefined') {
    window.location.href = '/concert/'
  }
}

// Main navigation items
const mainNavigation = ref([
  { text: 'Home', path: '/', icon: '🏠' },
  { text: 'Events', path: '/ProductPage', icon: '🎫' },
  { text: 'About', path: '/AboutUS', icon: 'ℹ️' }
])

// User menu items (when logged in)
const userMenuItems = ref([
  { text: 'Profile', path: '/ProfilePage', icon: '👤' },
  { text: 'My Events', path: '/AccountPage', icon: '📅' },
  { text: 'Settings', path: '/AccountPage', icon: '⚙️' }
])

const toggleMobileMenu = () => {
  isMobileMenuOpen.value = !isMobileMenuOpen.value
  isUserMenuOpen.value = false
}

const toggleUserMenu = () => {
  isUserMenuOpen.value = !isUserMenuOpen.value
}

// Close menus when clicking outside
const closeMenus = () => {
  isMobileMenuOpen.value = false
  isUserMenuOpen.value = false
}

onMounted(() => {
  if (typeof window !== 'undefined') {
    document.addEventListener('click', (e) => {
      const target = e.target as HTMLElement
      if (!target.closest('.navbar-container')) {
        closeMenus()
      }
    })
  }
})
</script>

<template>
  <nav class="navbar-container bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 shadow-lg fixed w-full z-50 top-0">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        
        <!-- Logo/Brand -->
        <div class="flex-shrink-0">
          <NuxtLink to="/" class="flex items-center gap-3 group">
            <span class="text-3xl">🎵</span>
            <span class="text-2xl font-bold text-white tracking-tight group-hover:scale-105 transition-transform">
              MM Concerts
            </span>
          </NuxtLink>
        </div>

        <!-- Desktop Navigation -->
        <div class="hidden md:flex md:items-center md:space-x-1">
          <NuxtLink
            v-for="item in mainNavigation"
            :key="item.path"
            :to="item.path"
            class="px-4 py-2 rounded-lg text-white font-medium hover:bg-white/20 transition-all duration-200 flex items-center gap-2"
            active-class="bg-white/30"
          >
            <span>{{ item.icon }}</span>
            <span>{{ item.text }}</span>
          </NuxtLink>
        </div>

        <!-- Desktop Right Side -->
        <div class="hidden md:flex items-center gap-3">
          
          <!-- Create Event Button (Only when logged in) -->
          <NuxtLink
            v-if="isLoggedIn"
            to="/CreateEventPage"
            class="px-4 py-2 bg-white text-purple-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors duration-200 flex items-center gap-2 shadow-md"
          >
            <span class="text-xl">➕</span>
            <span>Create Event</span>
          </NuxtLink>

          <!-- User Menu (Logged In) -->
          <div v-if="isLoggedIn" class="relative">
            <button
              @click.stop="toggleUserMenu"
              class="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/20 hover:bg-white/30 transition-colors"
              aria-label="User menu"
            >
              <div class="w-8 h-8 bg-white rounded-full flex items-center justify-center text-purple-600 font-bold">
                {{ user?.username?.[0]?.toUpperCase() || 'U' }}
              </div>
              <span class="text-white font-medium hidden lg:block">{{ user?.username || 'User' }}</span>
              <svg class="w-4 h-4 text-white" :class="{ 'rotate-180': isUserMenuOpen }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </button>

            <!-- User Dropdown Menu -->
            <Transition
              enter-active-class="transition ease-out duration-200"
              enter-from-class="opacity-0 scale-95"
              enter-to-class="opacity-100 scale-100"
              leave-active-class="transition ease-in duration-150"
              leave-from-class="opacity-100 scale-100"
              leave-to-class="opacity-0 scale-95"
            >
              <div
                v-if="isUserMenuOpen"
                class="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-2xl py-2 ring-1 ring-black ring-opacity-5"
              >
                <div class="px-4 py-3 border-b border-gray-100">
                  <p class="text-sm text-gray-500">Signed in as</p>
                  <p class="text-sm font-semibold text-gray-900 truncate">{{ user?.email }}</p>
                </div>
                
                <NuxtLink
                  v-for="item in userMenuItems"
                  :key="item.path"
                  :to="item.path"
                  class="flex items-center gap-3 px-4 py-2 text-gray-700 hover:bg-purple-50 transition-colors"
                  @click="isUserMenuOpen = false"
                >
                  <span class="text-lg">{{ item.icon }}</span>
                  <span class="font-medium">{{ item.text }}</span>
                </NuxtLink>
                
                <div class="border-t border-gray-100 mt-2 pt-2">
                  <button
                    @click="handleLogout"
                    class="w-full flex items-center gap-3 px-4 py-2 text-red-600 hover:bg-red-50 transition-colors font-medium"
                  >
                    <span class="text-lg">🚪</span>
                    <span>Sign Out</span>
                  </button>
                </div>
              </div>
            </Transition>
          </div>

          <!-- Login/Register Buttons (Not Logged In) -->
          <div v-else class="flex items-center gap-2">
            <NuxtLink
              to="/LoginPage"
              class="px-4 py-2 text-white font-medium hover:bg-white/20 rounded-lg transition-colors"
            >
              Sign In
            </NuxtLink>
            <NuxtLink
              to="/RegisterPage"
              class="px-4 py-2 bg-white text-purple-600 font-semibold rounded-lg hover:bg-gray-100 transition-colors shadow-md"
            >
              Get Started
            </NuxtLink>
          </div>
        </div>

        <!-- Mobile Menu Button -->
        <button
          @click.stop="toggleMobileMenu"
          class="md:hidden p-2 rounded-lg text-white hover:bg-white/20 transition-colors"
          aria-label="Toggle menu"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path v-if="!isMobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Mobile Menu -->
    <Transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0 -translate-y-4"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 -translate-y-4"
    >
      <div v-if="isMobileMenuOpen" class="md:hidden bg-white shadow-xl rounded-b-2xl">
        <div class="px-4 py-6 space-y-3">
          
          <!-- Mobile Navigation Links -->
          <NuxtLink
            v-for="item in mainNavigation"
            :key="item.path"
            :to="item.path"
            class="flex items-center gap-3 px-4 py-3 rounded-lg text-gray-700 font-medium hover:bg-purple-50 transition-colors"
            active-class="bg-purple-100 text-purple-600"
            @click="isMobileMenuOpen = false"
          >
            <span class="text-xl">{{ item.icon }}</span>
            <span>{{ item.text }}</span>
          </NuxtLink>

          <div class="border-t border-gray-200 pt-3 mt-3">
            
            <!-- Mobile - Logged In -->
            <div v-if="isLoggedIn" class="space-y-2">
              <div class="px-4 py-2 bg-purple-50 rounded-lg">
                <p class="text-sm text-gray-600">Signed in as</p>
                <p class="font-semibold text-gray-900">{{ user?.username }}</p>
              </div>

              <NuxtLink
                to="/CreateEventPage"
                class="flex items-center gap-3 px-4 py-3 bg-purple-600 text-white font-semibold rounded-lg hover:bg-purple-700 transition-colors"
                @click="isMobileMenuOpen = false"
              >
                <span class="text-xl">➕</span>
                <span>Create Event</span>
              </NuxtLink>

              <NuxtLink
                v-for="item in userMenuItems"
                :key="item.path"
                :to="item.path"
                class="flex items-center gap-3 px-4 py-3 rounded-lg text-gray-700 font-medium hover:bg-purple-50 transition-colors"
                @click="isMobileMenuOpen = false"
              >
                <span class="text-lg">{{ item.icon }}</span>
                <span>{{ item.text }}</span>
              </NuxtLink>

              <button
                @click="handleLogout"
                class="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-red-600 font-medium hover:bg-red-50 transition-colors"
              >
                <span class="text-lg">🚪</span>
                <span>Sign Out</span>
              </button>
            </div>

            <!-- Mobile - Not Logged In -->
            <div v-else class="space-y-2">
              <NuxtLink
                to="/LoginPage"
                class="block px-4 py-3 text-center text-purple-600 font-semibold rounded-lg border-2 border-purple-600 hover:bg-purple-50 transition-colors"
                @click="isMobileMenuOpen = false"
              >
                Sign In
              </NuxtLink>
              <NuxtLink
                to="/RegisterPage"
                class="block px-4 py-3 text-center bg-purple-600 text-white font-semibold rounded-lg hover:bg-purple-700 transition-colors"
                @click="isMobileMenuOpen = false"
              >
                Get Started
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </nav>
</template>

<style scoped>
/* Smooth transitions - using custom utility class */
.router-link-active {
  background-color: rgb(255 255 255 / 0.3);
}
</style>