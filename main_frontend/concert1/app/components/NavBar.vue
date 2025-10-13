<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'

const router = useRouter()
const { loadFromStorage, isLoggedIn, clearAuth } = useAuth()
const { push: toast } = useToast()
const showLogoutModal = ref(false)

const pages = ref([
    { text: 'Home', value: '/'},
    { text: 'Events', value: '/ProductPage'},
    { text: 'My Events', value: '/MyEventsPage'},
    { text: 'My Bookings', value: '/MyBookingsPage'},
    { text: 'Account', value: '/AccountPage'}
])

const authPages = ref([
    { text: 'Create Event', value: '/CreateEventPage'},
    { text: 'Login', value: '/LoginPage'},
    { text: 'Register', value: '/RegisterPage'}
])

onMounted(() => {
  loadFromStorage()
})

function handleLogout() {
  showLogoutModal.value = true
}

function confirmLogout() {
  clearAuth()
  localStorage.removeItem('profile_data')
  showLogoutModal.value = false
  toast('Logged out successfully', 'success')
  router.push('/')
}

function cancelLogout() {
  showLogoutModal.value = false
}
</script>

<template>
    <nav class="bg-black text-white fixed w-full z-20 top-0 start-0 border-b">
        <div class="max-w-6xl flex flex-wrap items-center justify-between mx-auto p-4">
            <NuxtLink to="/">
                <span class="self-center text-2xl font-semibold whitespace-nowrap">MM concerts</span>
            </NuxtLink>
            
            <!-- Main Navigation -->
            <ul class="flex flex-row">
                <li v-for="page in pages" :key="page.value">
                    <NuxtLink :to="`${page.value}`" class="hover:text-blue-400 p-3">{{ page.text }}</NuxtLink>
                </li>
            </ul>

            <!-- Auth Navigation -->
            <ul class="flex flex-row items-center">
                <li v-if="!isLoggedIn" v-for="page in authPages" :key="page.value">
                    <NuxtLink :to="`${page.value}`" class="hover:text-blue-400 p-3">{{ page.text }}</NuxtLink>
                </li>
                <li v-if="isLoggedIn">
                    <NuxtLink to="/CreateEventPage" class="hover:text-blue-400 p-3">Create Event</NuxtLink>
                </li>
                <li v-if="isLoggedIn">
                    <button 
                        @click="handleLogout" 
                        class="ml-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-all text-sm"
                    >
                        🚪 Logout
                    </button>
                </li>
            </ul>
        </div>
    </nav>

    <!-- Logout Confirmation Modal -->
    <LogoutModal 
      :show="showLogoutModal" 
      @confirm="confirmLogout" 
      @cancel="cancelLogout" 
    />
</template>