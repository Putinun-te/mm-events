<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuth } from '~/composables/useAuth'

const { loadFromStorage, isLoggedIn } = useAuth()

let fullName = ref('')
let email = ref('')
let password = ref('')
let firstName = ref('')
let lastName = ref('')
let phone = ref<string | number>('')
let address = ref('')
let city = ref('')
let country = ref('')
let pincode = ref<string | number>('')

const message = ref('')
const isSuccess = ref(false)

onMounted(() => {
  if (process.client) {
    loadFromStorage()
    if (!isLoggedIn.value) {
      // require login before accessing profile
      navigateTo('/LoginPage')
      return
    }
    // prefill from saved profile if exists
    try {
      const saved = localStorage.getItem('profile_data')
      if (saved) {
        const p = JSON.parse(saved)
        fullName.value = p.fullName || ''
        email.value = p.email || ''
        firstName.value = p.firstName || ''
        lastName.value = p.lastName || ''
        phone.value = p.phone || ''
        address.value = p.address || ''
        city.value = p.city || ''
        country.value = p.country || ''
        pincode.value = p.pincode || ''
      } else {
        // default email from auth storage
        email.value = localStorage.getItem('user_email') || sessionStorage.getItem('user_email') || ''
      }
    } catch {}
  }
})

function buildPayload() {
  return {
    firstName: firstName.value,
    lastName: lastName.value,
    phone: phone.value?.toString() || '',
    address: address.value,
    city: city.value,
    country: country.value,
    pincode: pincode.value?.toString() || '',
  }
}

async function handleSubmit() {
  message.value = ''
  isSuccess.value = false

  if (!firstName.value || !lastName.value) {
    message.value = 'Please provide your first and last name'
    return
  }

  try {
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token') || ''
    const res: any = await $fetch('/api/users/me', {
      method: 'PUT',
      body: buildPayload(),
      headers: { Authorization: `Bearer ${token}` }
    })

    // local cache and flag
    localStorage.setItem('profile_data', JSON.stringify({ ...buildPayload(), email: email.value }))
    localStorage.setItem('profile_completed', 'true')

    isSuccess.value = true
    message.value = 'Profile saved successfully'
  } catch (e: any) {
    console.error('Save profile error', e)
    message.value = e?.data?.message || 'Failed to save profile'
  }
}

</script>
<template>
  <div class="bg-white rounded shadow-sm py-12 sm:py-16">
    <div class="flex items-center justify-center">
      <form @submit.prevent="handleSubmit" class="w-full max-w-2xl">
        <div class="p-6 md:p-8">
          <h1 class="text-3xl font-bold text-gray-900">Account Information</h1>

          <div v-if="message" :class="['mt-4 px-3 py-2 rounded text-center', isSuccess ? 'bg-green-500 text-white' : 'bg-red-500 text-white']">
            <p>{{ message }}</p>
          </div>

          <div class="mt-10">
            <h2 class="text-lg font-semibold leading-7 text-gray-800">Profile Photo</h2>
            <div class="mt-4 flex items-center justify-center mb-4">
              <div class="relative w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center text-gray-400"></div>
            </div>
          </div>

          <div class="mt-8">
            <h2 class="text-xl font-semibold leading-7 text-gray-800">Profile Information</h2>
            <div class="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-5">
              <div>
                <label for="first-name" class="block text-sm font-medium text-gray-700">First Name</label>
                <input v-model="firstName" type="text" id="first-name" placeholder="Enter first name" class="mt-1 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div>
                <label for="last-name" class="block text-sm font-medium text-gray-700">Last Name</label>
                <input v-model="lastName" type="text" id="last-name" placeholder="Enter last name" class="mt-1 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
            </div>
          </div>

          <div class="mt-10">
            <h2 class="text-xl font-semibold leading-7 text-gray-800">Contact Details</h2>
            <p class="mt-1 text-sm text-gray-500">These details are private and only used to contact you for ticketing or prizes.</p>
            <div class="mt-6 space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="phone" class="text-sm font-medium text-gray-700">Phone Number</label>
                <input v-model="phone" type="text" id="phone" placeholder="Enter phone number" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="address" class="text-sm font-medium text-gray-700">Address</label>
                <input v-model="address" type="text" id="address" placeholder="Enter address" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="city" class="text-sm font-medium text-gray-700">City/Town</label>
                <input v-model="city" type="text" id="city" placeholder="Enter city" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="country" class="text-sm font-medium text-gray-700">Country</label>
                <input v-model="country" type="text" id="country" placeholder="Enter country" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="pincode" class="text-sm font-medium text-gray-700">Pincode</label>
                <input v-model="pincode" type="text" id="pincode" placeholder="Enter pincode" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
            </div>
          </div>
          
          <div class="mt-10">
            <button type="submit" class="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white transition-colors" style="background-color: #362e54;" onmouseover="this.style.backgroundColor='#4a3f70'" onmouseout="this.style.backgroundColor='#362e54'">Save My Profile</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>