<script setup lang="ts">
import { reactive, ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'

interface CreateEventForm {
  title: string
  description: string
  personLimit: number | null
  dateStart: string
  timeStart: string
  dateEnd: string
  timeEnd: string
  ticketPrice: number | null
  address?: string
  city?: string
  country?: string
  phone?: string
  category?: string
  location?: string
}

const router = useRouter()
const { loadFromStorage, isLoggedIn, user } = useAuth()
const { success, error } = useToast()

const submitting = ref(false)

// Event categories matching the catalog
const categories = ['Music', 'Sports', 'Tech', 'Art', 'Food', 'Business', 'Other']

const form = reactive<CreateEventForm>({
  title: '',
  description: '',
  personLimit: null,
  dateStart: '',
  timeStart: '',
  dateEnd: '',
  timeEnd: '',
  ticketPrice: null,
  address: '',
  city: '',
  country: '',
  phone: '',
  category: '',
  location: ''
})

const startISO = computed(() => form.dateStart && form.timeStart ? `${form.dateStart}T${form.timeStart}:00` : '')
const endISO = computed(() => form.dateEnd && form.timeEnd ? `${form.dateEnd}T${form.timeEnd}:00` : '')

onMounted(() => {
  loadFromStorage()
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
  }
})

function validate(): string | null {
  if (!form.title.trim()) return 'Please fill in the event name.'
  if (!form.description.trim()) return 'Please add a description.'
  if (!form.dateStart || !form.timeStart) return 'Please select a start date and time.'
  if (!form.dateEnd || !form.timeEnd) return 'Please select an end date and time.'
  const s = new Date(startISO.value)
  const e = new Date(endISO.value)
  if (isNaN(s.getTime()) || isNaN(e.getTime())) return 'Invalid start/end date.'
  if (e <= s) return 'End time must be after start time.'
  return null
}

async function handleSubmit() {
  const err = validate()
  if (err) {
    error(err, 'Validation Error')
    return
  }
  const token = user.value?.token || localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
  if (!token) {
    error('You must be logged in to create an event.', 'Authentication Required')
    router.push('/LoginPage')
    return
  }

  submitting.value = true
  try {
    const payload: any = {
      title: form.title,
      description: form.description || null,
      personLimit: form.personLimit ?? null,
      startDate: startISO.value,
      endDate: endISO.value,
      ticketPrice: form.ticketPrice ?? null,
      address: form.address || null,
      city: form.city || null,
      country: form.country || null,
      phone: form.phone || null,
      category: form.category || null,
      location: form.location || null
    }
    
    // Save to JSON file
    await $fetch('/api/events/json', {
      method: 'POST',
      body: payload,
      headers: { Authorization: `Bearer ${token}` }
    })
    
    success('Event created successfully and saved to JSON!', 'Event Created')
    router.push('/ProductPage')
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to create event.'
    error(message, 'Creation Failed')
  } finally {
    submitting.value = false
  }
}

</script>

<template>
  <div class="bg-white rounded shadow-sm py-12 sm:py-16">
    <div class="flex items-center justify-center">
      <form @submit.prevent="handleSubmit" class="w-full max-w-2xl">
        <div class="p-6 md:p-8">
          <h1 class="text-3xl font-bold text-gray-900">Create Event</h1>

          <div class="mt-10">
            <h2 class="text-lg font-semibold leading-7 text-gray-800">Event Picture</h2>
            <div class="mt-4 flex items-center justify-center mb-4">
              <div class="relative w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center text-gray-400">
                <!-- <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg> -->
              </div>
            </div>
          </div>


          <div class="mt-10">
            <h2 class="text-xl font-semibold leading-7 text-gray-800">Event Details</h2>
            <p class="mt-1 text-sm text-gray-500">Our team will carefully consider them and get back to you within 24 hours.</p>
            <div class="mt-6 space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="event name" class="text-sm font-medium text-gray-700">Event Name</label>
                <input v-model="form.title" type="text" placeholder="Enter Event name" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="description" class="text-sm font-medium text-gray-700">Description</label>
                <input v-model="form.description" type="text" placeholder="Enter description and additional information" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              
              <!-- Category Selector -->
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-start">
                <label for="category" class="text-sm font-medium text-gray-700 pt-2">Event Type</label>
                <div class="md:col-span-2 mt-1 md:mt-0">
                  <div class="flex flex-wrap gap-2">
                    <button
                      v-for="cat in categories"
                      :key="cat"
                      type="button"
                      @click="form.category = cat"
                      :class="[
                        'px-4 py-2 rounded-full text-sm font-medium transition-all duration-200',
                        form.category === cat
                          ? 'bg-violet-600 text-white shadow-md'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      ]"
                    >
                      {{ cat }}
                    </button>
                  </div>
                  <p v-if="form.category" class="mt-2 text-xs text-gray-500">
                    Selected: <span class="font-semibold text-violet-600">{{ form.category }}</span>
                  </p>
                </div>
              </div>
              
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label for="limit people" class="text-sm font-medium text-gray-700">People</label>
                <input v-model.number="form.personLimit" type="number" min="0" placeholder="Enter Limit People" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">Event start</label>
                <div class="md:col-span-2 grid grid-cols-2 gap-2">
                  <input v-model="form.dateStart" type="date" class="block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                  <input v-model="form.timeStart" type="time" class="block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">Event end</label>
                <div class="md:col-span-2 grid grid-cols-2 gap-2">
                  <input v-model="form.dateEnd" type="date" class="block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                  <input v-model="form.timeEnd" type="time" class="block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">Ticket price</label>
                <input v-model.number="form.ticketPrice" type="number" min="0" step="0.01" placeholder="Optional" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">Address</label>
                <input v-model="form.address" type="text" placeholder="Optional" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">City</label>
                <input v-model="form.city" type="text" placeholder="Optional" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">Country</label>
                <input v-model="form.country" type="text" placeholder="Optional" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-x-4 items-center">
                <label class="text-sm font-medium text-gray-700">Phone</label>
                <input v-model="form.phone" type="tel" placeholder="Optional" class="md:col-span-2 mt-1 md:mt-0 block w-full px-3 py-2 bg-white border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
              </div>
            </div>
          </div>
          
          <div class="mt-10">
            <button :disabled="submitting" type="submit" class="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white transition-colors disabled:opacity-60" style="background-color: #362e54;" onmouseover="this.style.backgroundColor='#4a3f70'" onmouseout="this.style.backgroundColor='#362e54'">
              {{ submitting ? 'Submitting...' : 'Create Event' }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>