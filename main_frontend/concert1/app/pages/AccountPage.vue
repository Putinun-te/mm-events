<script setup lang="ts">
import { reactive, ref, onMounted, computed } from 'vue'
import { useAuth } from '~/composables/useAuth'
import { useRouter } from 'vue-router'
import { useToast } from '~/composables/useToast'
import { useApi } from '../../composables/useApi'

interface UserForm {
  fullName: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phone: string;
  address: string;
  city: string;
  country: string;
  pincode: number;
}

interface UserStats {
  eventsCreated: number;
  ticketsPurchased: number;
  upcomingEvents: number;
}

const router = useRouter()
const { loadFromStorage, isLoggedIn, clearAuth } = useAuth()
const saving = ref(false)
const message = ref('')
const successFlag = ref(false)
const { success, error } = useToast()
const { apiFetch } = useApi()
const activeTab = ref<'profile' | 'stats'>('profile')
const showLogoutConfirm = ref(false)

const userData = reactive<UserForm>({
  fullName: "",
  email: "",
  password: "",
  firstName: "",
  lastName: "",
  phone: "",
  address: "",
  city: "",
  country: "",
  pincode: 0
})

const stats = ref<UserStats>({
  eventsCreated: 0,
  ticketsPurchased: 0,
  upcomingEvents: 0
})

const userInitials = computed(() => {
  if (userData.firstName) {
    const first = userData.firstName.charAt(0).toUpperCase()
    const last = userData.lastName ? userData.lastName.charAt(0).toUpperCase() : ''
    return first + last
  }
  return userData.email ? userData.email.charAt(0).toUpperCase() : '?'
})

onMounted(async () => {
  loadFromStorage()
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
    return
  }
  await loadUserData()
  await loadUserStats()
})

async function loadUserData() {
  try {
    // Load from API to get current data
    const profile = await apiFetch('/api/users/profile')
    if (profile) {
      userData.email = profile.email || ''
      userData.fullName = profile.name || ''
      userData.phone = profile.phone || ''
      userData.address = profile.address || ''
      userData.city = profile.city || ''
      userData.country = profile.country || ''
      userData.pincode = profile.pincode ? Number(profile.pincode) : 0
      
      if (userData.fullName) {
        const parts = userData.fullName.split(' ')
        userData.firstName = parts.shift() || ''
        userData.lastName = parts.join(' ')
      }
    }
  } catch (e: any) {
    console.error('Failed to load profile:', e)
    message.value = 'Failed to load profile. Please refresh the page.'
    // Fallback to stored data
    const storedEmail = localStorage.getItem('user_email') || sessionStorage.getItem('user_email')
    const storedUsername = localStorage.getItem('username') || sessionStorage.getItem('username')
    
    if (storedEmail) userData.email = storedEmail
    if (storedUsername) userData.fullName = storedUsername
  }
}

async function loadUserStats() {
  // Set default stats to avoid API calls that cause login loops
  stats.value.eventsCreated = 0
  stats.value.ticketsPurchased = 0
  stats.value.upcomingEvents = 0
}

async function handlesubmit () {
  message.value = ''
  successFlag.value = false
  if (!userData.firstName.trim()) {
    message.value = 'Please provide at least your first name.'
    error('Please provide at least your first name.', 'Validation Error')
    return
  }
  saving.value = true
  try {
    // Check token first
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    if (!token) {
      message.value = 'Not authenticated'
      error('Not authenticated', 'Authentication Required')
      router.push('/LoginPage')
      return
    }

    const payload = {
      firstName: userData.firstName?.trim() || null,
      lastName: userData.lastName?.trim() || null,
      phone: userData.phone?.trim() || null,
      address: userData.address?.trim() || null,
      city: userData.city?.trim() || null,
      country: userData.country?.trim() || null,
      pincode: userData.pincode ? String(userData.pincode) : null
    }
    
    console.log('Profile update request:', payload)
    
    const res: any = await apiFetch('/api/users/profile', {
      method: 'PUT',
      body: payload
    })
    
    console.log('Profile update response:', res)
    
    // Update local data with response
    if (res) {
      userData.fullName = res.name || ''
      userData.phone = res.phone || ''
      userData.address = res.address || ''
      userData.city = res.city || ''
      userData.country = res.country || ''
      userData.pincode = res.pincode ? Number(res.pincode) : 0
      
      if (userData.fullName) {
        const parts = userData.fullName.split(' ')
        userData.firstName = parts.shift() || ''
        userData.lastName = parts.join(' ')
      }
    }
    
    successFlag.value = true
    message.value = 'Profile updated successfully!'
    success('Profile updated successfully!', 'Success')
  } catch (e: any) {
    console.error('Profile update failed:', e)
    let msg = 'Failed to save profile.'
    if (e?.data?.message) {
      msg = e.data.message
    } else if (e?.message && e?.message !== '[object Object]') {
      msg = e.message
    }
    message.value = msg
    error(msg, 'Profile Update Error')
    if (e?.status === 401 || e?.response?.status === 401) {
      router.push('/LoginPage')
    }
  } finally {
    saving.value = false
  }
}

function handleLogout() {
  showLogoutConfirm.value = true
}

function confirmLogout() {
  clearAuth()
  localStorage.removeItem('profile_data')
  success('Logged out successfully', 'Goodbye!')
  router.push('/')
}

function cancelLogout() {
  showLogoutConfirm.value = false
}
</script>
<template>
  <div class="bg-gray-50 min-h-screen py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      
      <!-- Header with Profile Summary -->
      <div class="bg-white rounded-2xl shadow-lg p-6 md:p-8 mb-8">
        <div class="flex flex-col md:flex-row items-center md:items-start gap-6">
          <!-- Profile Avatar -->
          <div class="relative">
            <div class="w-24 h-24 bg-gradient-to-br from-violet-500 to-purple-600 rounded-full flex items-center justify-center text-white text-3xl font-bold shadow-lg">
              {{ userInitials }}
            </div>
            <button class="absolute bottom-0 right-0 bg-white rounded-full p-2 shadow-md hover:shadow-lg transition-shadow">
              📷
            </button>
          </div>
          
          <!-- Profile Info -->
          <div class="flex-1 text-center md:text-left">
            <h1 class="text-3xl font-bold text-gray-900">{{ userData.fullName || 'Welcome' }}</h1>
            <p class="text-gray-600 mt-1">{{ userData.email }}</p>
            <div class="flex flex-wrap gap-2 mt-4 justify-center md:justify-start">
              <span class="px-3 py-1 bg-violet-100 text-violet-700 rounded-full text-sm font-semibold">Member</span>
              <span v-if="userData.city" class="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm">📍 {{ userData.city }}</span>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="flex flex-col gap-2">
            <button @click="router.push('/CreateEventPage')" class="px-6 py-2 bg-gradient-to-r from-violet-600 to-purple-600 text-white rounded-lg font-semibold hover:shadow-lg transition-all">
              + Create Event
            </button>
            <button @click="router.push('/MyBookingsPage')" class="px-6 py-2 border-2 border-violet-600 text-violet-600 rounded-lg font-semibold hover:bg-violet-50 transition-all">
              My Bookings
            </button>
            <button @click="handleLogout" class="px-6 py-2 border-2 border-red-500 text-red-600 rounded-lg font-semibold hover:bg-red-50 transition-all">
              🚪 Logout
            </button>
          </div>
        </div>
      </div>

      <!-- Stats Cards (Eventpop-like) -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white rounded-xl shadow-md p-6 border-l-4 border-blue-500">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-600 text-sm font-medium">Events Created</p>
              <p class="text-3xl font-bold text-gray-900 mt-2">{{ stats.eventsCreated }}</p>
            </div>
            <div class="text-4xl">🎪</div>
          </div>
          <button @click="router.push('/MyEventsPage')" class="text-blue-600 text-sm font-semibold mt-3 hover:underline">View All →</button>
        </div>

        <div class="bg-white rounded-xl shadow-md p-6 border-l-4 border-green-500">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-600 text-sm font-medium">Tickets Purchased</p>
              <p class="text-3xl font-bold text-gray-900 mt-2">{{ stats.ticketsPurchased }}</p>
            </div>
            <div class="text-4xl">🎫</div>
          </div>
          <button @click="router.push('/MyBookingsPage')" class="text-green-600 text-sm font-semibold mt-3 hover:underline">View Tickets →</button>
        </div>

        <div class="bg-white rounded-xl shadow-md p-6 border-l-4 border-purple-500">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-gray-600 text-sm font-medium">Upcoming Events</p>
              <p class="text-3xl font-bold text-gray-900 mt-2">{{ stats.upcomingEvents }}</p>
            </div>
            <div class="text-4xl">📅</div>
          </div>
          <button @click="router.push('/product-page')" class="text-purple-600 text-sm font-semibold mt-3 hover:underline">Browse Events →</button>
        </div>
      </div>

      <!-- Tabs -->
      <div class="bg-white rounded-t-2xl shadow-lg">
        <div class="border-b border-gray-200">
          <div class="flex">
            <button 
              @click="activeTab = 'profile'" 
              :class="['flex-1 px-6 py-4 font-semibold transition-colors', activeTab === 'profile' ? 'text-violet-600 border-b-2 border-violet-600' : 'text-gray-500 hover:text-gray-700']"
            >
              ✏️ Edit Profile
            </button>
            <button 
              @click="activeTab = 'stats'" 
              :class="['flex-1 px-6 py-4 font-semibold transition-colors', activeTab === 'stats' ? 'text-violet-600 border-b-2 border-violet-600' : 'text-gray-500 hover:text-gray-700']"
            >
              📊 Activity
            </button>
          </div>
        </div>

        <!-- Tab Content -->
        <div class="p-6 md:p-8">
          <!-- Profile Edit Tab -->
          <div v-if="activeTab === 'profile'">
            <form @submit.prevent="handlesubmit">
              <div v-if="message" :class="['mb-6 px-4 py-3 rounded-lg', successFlag ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200']">
                {{ message }}
              </div>

              <!-- Personal Information -->
              <div class="mb-8">
                <h3 class="text-xl font-semibold text-gray-900 mb-4">Personal Information</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">First Name *</label>
                    <input
                      v-model="userData.firstName"
                      type="text" 
                      required
                      placeholder="Enter first name" 
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
                    <input 
                      v-model="userData.lastName" 
                      type="text" 
                      placeholder="Enter last name" 
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
                    <input 
                      v-model="userData.email" 
                      type="email" 
                      disabled
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg bg-gray-50 cursor-not-allowed"
                    />
                    <p class="text-xs text-gray-500 mt-1">Email cannot be changed</p>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Phone Number</label>
                    <input 
                      v-model="userData.phone" 
                      type="tel" 
                      placeholder="Enter phone number" 
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                    />
                  </div>
                </div>
              </div>

              <!-- Address Information -->
              <div class="mb-8">
                <h3 class="text-xl font-semibold text-gray-900 mb-4">Address Information</h3>
                <div class="space-y-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Street Address</label>
                    <input 
                      v-model="userData.address" 
                      type="text" 
                      placeholder="Enter street address" 
                      class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                    />
                  </div>
                  <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-2">City</label>
                      <input 
                        v-model="userData.city" 
                        type="text" 
                        placeholder="Enter city" 
                        class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-2">Country</label>
                      <input 
                        v-model="userData.country" 
                        type="text" 
                        placeholder="Enter country" 
                        class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-2">Postal Code</label>
                      <input 
                        v-model="userData.pincode" 
                        type="number" 
                        placeholder="Enter postal code" 
                        class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-violet-500 transition-all"
                      />
                    </div>
                  </div>
                </div>
              </div>

              <!-- Save Button -->
              <div class="flex justify-end">
                <button 
                  type="submit" 
                  :disabled="saving"
                  class="px-8 py-3 bg-gradient-to-r from-violet-600 to-purple-600 text-white font-semibold rounded-lg shadow-md hover:shadow-lg transform hover:scale-105 transition-all duration-200 disabled:opacity-60 disabled:transform-none"
                >
                  <span v-if="saving" class="flex items-center gap-2">
                    <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Saving...
                  </span>
                  <span v-else>💾 Save Changes</span>
                </button>
              </div>
            </form>
          </div>

          <!-- Activity Tab -->
          <div v-else-if="activeTab === 'stats'" class="space-y-6">
            <div class="text-center py-12">
              <div class="text-6xl mb-4">📈</div>
              <h3 class="text-2xl font-bold text-gray-900 mb-2">Your Activity Dashboard</h3>
              <p class="text-gray-600 mb-8">Track your events and bookings over time</p>
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-2xl mx-auto">
                <div class="bg-gradient-to-br from-blue-50 to-blue-100 p-6 rounded-xl">
                  <div class="text-4xl mb-2">{{ stats.eventsCreated }}</div>
                  <div class="font-semibold text-blue-900">Total Events Created</div>
                  <button @click="router.push('/MyEventsPage')" class="mt-3 text-blue-600 hover:underline text-sm font-medium">Manage Events →</button>
                </div>
                
                <div class="bg-gradient-to-br from-green-50 to-green-100 p-6 rounded-xl">
                  <div class="text-4xl mb-2">{{ stats.ticketsPurchased }}</div>
                  <div class="font-semibold text-green-900">Total Tickets Purchased</div>
                  <button @click="router.push('/MyBookingsPage')" class="mt-3 text-green-600 hover:underline text-sm font-medium">View Tickets →</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Logout Confirmation Modal -->
    <LogoutModal 
      :show="showLogoutConfirm" 
      @confirm="confirmLogout" 
      @cancel="cancelLogout" 
    />
  </div>
</template>