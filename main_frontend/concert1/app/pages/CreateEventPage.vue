<script setup lang="ts">
import { reactive, ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'
import { useApi } from '../../composables/useApi'

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
const { success, error, warning } = useToast()
const { apiFetch, backendUrl } = useApi()

const submitting = ref(false)
const photoFile = ref<File | null>(null)
const photoPreview = ref<string | null>(null)
const photoUrl = ref('')
const uploadMode = ref<'file' | 'url'>('file')

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

function handlePhotoSelect(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return
  
  photoFile.value = file
  photoUrl.value = ''
  
  const reader = new FileReader()
  reader.onload = (e) => {
    photoPreview.value = e.target?.result as string
  }
  reader.readAsDataURL(file)
}

function handleUrlInput() {
  if (photoUrl.value) {
    photoPreview.value = photoUrl.value
    photoFile.value = null
  }
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
      location: form.location || null,
      photoUrl: null  // Will be set after S3 upload
    }
    
    // Create event in backend
    const backendEvent: any = await apiFetch('/api/events/json', {
      method: 'POST',
      body: payload,
      headers: { Authorization: `Bearer ${token}` }
    })

    // Handle photo upload or URL
    let finalPhotoUrl = photoUrl.value
    
    if (photoFile.value && backendEvent?.id) {
      try {
        const formData = new FormData()
        formData.append('file', photoFile.value)
        
        const uploadResponse = await fetch(`${backendUrl}/api/upload/event-photo`, {
          method: 'POST',
          body: formData
        })
        
        if (uploadResponse.ok) {
          const { url } = await uploadResponse.json()
          finalPhotoUrl = url
        }
      } catch (uploadErr) {
        console.error('Photo upload failed:', uploadErr)
        warning('Event created but photo upload failed', 'Partial Success')
      }
    }
    
    if (finalPhotoUrl && backendEvent?.id) {
      await apiFetch(`/api/events/${backendEvent.id}`, {
        method: 'PUT',
        body: { ...payload, photoUrl: finalPhotoUrl },
        headers: { Authorization: `Bearer ${token}` }
      })
    }

    success('Event created successfully!', 'Event Created')
    router.push('/product-page')
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
            <h2 class="text-lg font-semibold leading-7 text-gray-800">Event Picture (Optional)</h2>
            <div class="mt-4 flex flex-col gap-4">
              <div v-if="photoPreview" class="relative w-full h-64 rounded-lg overflow-hidden border-2 border-gray-300">
                <img :src="photoPreview" alt="Preview" class="w-full h-full object-cover" />
                <button type="button" @click="photoFile = null; photoPreview = null; photoUrl = ''" class="absolute top-2 right-2 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center hover:bg-red-600">
                  ✕
                </button>
              </div>
              
              <div class="flex gap-2 mb-2">
                <button type="button" @click="uploadMode = 'file'" :class="['px-4 py-2 rounded-md text-sm font-medium', uploadMode === 'file' ? 'bg-violet-600 text-white' : 'bg-gray-200 text-gray-700']">
                  Upload File
                </button>
                <button type="button" @click="uploadMode = 'url'" :class="['px-4 py-2 rounded-md text-sm font-medium', uploadMode === 'url' ? 'bg-violet-600 text-white' : 'bg-gray-200 text-gray-700']">
                  Use URL
                </button>
              </div>
              
              <input v-if="uploadMode === 'file'" type="file" accept="image/*" @change="handlePhotoSelect" class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-violet-50 file:text-violet-700 hover:file:bg-violet-100" />
              
              <div v-if="uploadMode === 'url'" class="flex gap-2">
                <input v-model="photoUrl" type="url" placeholder="https://example.com/image.jpg" class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-violet-500" />
                <button type="button" @click="handleUrlInput" class="px-4 py-2 bg-violet-600 text-white rounded-md hover:bg-violet-700">
                  Preview
                </button>
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