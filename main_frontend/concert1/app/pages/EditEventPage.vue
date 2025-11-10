<script setup lang="ts">
import { reactive, ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
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
const route = useRoute()
const { loadFromStorage, isLoggedIn, user } = useAuth()
const { success, error } = useToast()
const { apiFetch, backendUrl } = useApi()

const submitting = ref(false)
const loading = ref(true)
const showDeleteModal = ref(false)
const eventId = route.query.id
// Photo upload removed - use UploadPhotoPage
const photoInput = ref<HTMLInputElement | null>(null)
const photoFile = ref<File | null>(null)
const photoPreview = ref<string | null>(null)
const photoUploading = ref(false)

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

onMounted(async () => {
  loadFromStorage()
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
    return
  }
  
  if (!eventId) {
    error('No event ID provided', 'Invalid Request')
    router.push('/MyEventsPage')
    return
  }
  
  await loadEventData()
})

async function loadEventData() {
  loading.value = true
  try {
    const token = user.value?.token || localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    if (!token) {
      router.push('/LoginPage')
      return
    }
    
    const event: any = await apiFetch(`/api/events/${eventId}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    
    if (!event) {
      error('Event not found', 'Error')
      router.push('/MyEventsPage')
      return
    }
    
    // Populate form with existing data
    form.title = event.title || event.name || ''
    form.description = event.description || ''
    form.personLimit = event.personLimit || event.personlimit || null
    form.ticketPrice = event.ticketPrice || null
    form.address = event.address || ''
    form.city = event.city || ''
    form.country = event.country || ''
    form.phone = event.phone || ''
    form.category = event.category || ''
    form.location = event.location || ''
    
    // Parse dates
    const startDate = event.startDate || event.datestart
    const endDate = event.endDate || event.dateend
    
    if (startDate) {
      const start = new Date(typeof startDate === 'number' ? startDate * 1000 : startDate)
      form.dateStart = start.toISOString().split('T')[0] || ''
      form.timeStart = start.toTimeString().substring(0, 5) || ''
    }
    
    if (endDate) {
      const end = new Date(typeof endDate === 'number' ? endDate * 1000 : endDate)
      form.dateEnd = end.toISOString().split('T')[0] || ''
      form.timeEnd = end.toTimeString().substring(0, 5) || ''
    }
    
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to load event'
    error(message, 'Load Failed')
    router.push('/MyEventsPage')
  } finally {
    loading.value = false
  }
}

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
    error('You must be logged in to edit an event.', 'Authentication Required')
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
    
    // Update event
    const updatedEvent: any = await apiFetch(`/api/events/${eventId}`, {
      method: 'PUT',
      body: payload,
      headers: { Authorization: `Bearer ${token}` }
    })
    
    // Upload photo if selected
    if (photoFile.value) {
      const formData = new FormData()
      formData.append('file', photoFile.value)
      photoUploading.value = true
      try {
        const uploadResponse = await fetch(`${backendUrl}/api/upload/event-photo`, {
          method: 'POST',
          body: formData
        })
        if (uploadResponse.ok) {
          const { url } = await uploadResponse.json()
          await apiFetch(`/api/events/${eventId}`, {
            method: 'PUT',
            body: { ...payload, photoUrl: url },
            headers: { Authorization: `Bearer ${token}` }
          })
        }
      } catch (uploadErr: any) {
        console.error('Photo upload failed:', uploadErr)
      } finally {
        photoUploading.value = false
      }
    }
    
    success('Event updated successfully!', 'Event Updated')
    router.push('/MyEventsPage')
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to update event.'
    error(message, 'Update Failed')
  } finally {
    submitting.value = false
  }
}

function openDeleteModal() {
  showDeleteModal.value = true
}

function closeDeleteModal() {
  showDeleteModal.value = false
}

function triggerPhotoSelect() {
  photoInput.value?.click()
}

function handlePhotoChange(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) {
    photoFile.value = null
    photoPreview.value = null
    return
  }
  photoFile.value = file
  photoPreview.value = URL.createObjectURL(file)
}

function clearPhoto() {
  photoFile.value = null
  photoPreview.value = null
  if (photoInput.value) photoInput.value.value = ''
}

async function confirmDelete() {
  const token = user.value?.token || localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
  if (!token) {
    error('You must be logged in', 'Authentication Required')
    router.push('/LoginPage')
    return
  }

  try {
    await apiFetch(`/api/events/${eventId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    })
    
    success('Event deleted successfully', 'Event Deleted')
    router.push('/MyEventsPage')
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to delete event.'
    error(message, 'Delete Failed')
  } finally {
    showDeleteModal.value = false
  }
}

</script>

<template>
  <div class="bg-gray-50 min-h-screen py-8">
    <!-- Loading State -->
    <div v-if="loading" class="container mx-auto px-4 text-center">
      <div class="bg-white rounded-lg shadow-sm p-8">
        <p class="text-gray-500">Loading event details...</p>
      </div>
    </div>

    <!-- Edit Form -->
    <div v-else class="container mx-auto px-4 max-w-4xl">
      <div class="bg-white rounded-lg shadow-sm">
        <div class="p-6 md:p-8">
          <!-- Header with Delete Button -->
          <div class="flex items-center justify-between mb-8">
            <div>
              <h1 class="text-3xl font-bold text-gray-900">Edit Event</h1>
              <p class="text-sm text-gray-500 mt-1">Update your event details below</p>
            </div>
            <button
              type="button"
              @click="openDeleteModal"
              class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-semibold"
            >
              Delete Event
            </button>
          </div>

          <form @submit.prevent="handleSubmit">
            <div class="mt-6">
              <h2 class="text-lg font-semibold leading-7 text-gray-800">Event Picture</h2>
              <div class="mt-4 flex items-center justify-center mb-4">
                <div class="relative w-32 h-32 rounded-full overflow-hidden bg-gray-200 flex items-center justify-center text-gray-400">
                  <template v-if="photoPreview">
                    <img :src="photoPreview" alt="Event preview" class="w-full h-full object-cover" />
                    <button type="button" class="absolute top-2 right-2 bg-white bg-opacity-80 rounded-full px-2 py-1 text-xs font-semibold text-gray-700" @click="clearPhoto">✕</button>
                  </template>
                  <template v-else>
                    <span class="text-sm text-gray-500">No image</span>
                  </template>
                </div>
              </div>
              <div class="flex flex-col items-center gap-2">
                <input ref="photoInput" type="file" accept="image/*" class="hidden" @change="handlePhotoChange" />
                <button type="button" class="px-4 py-2 bg-indigo-600 text-white rounded-md text-sm font-medium hover:bg-indigo-700 transition" @click="triggerPhotoSelect" :disabled="photoUploading || submitting">
                  {{ photoFile ? 'Change Picture' : 'Upload Picture' }}
                </button>
                <p v-if="photoUploading" class="text-xs text-gray-500">Uploading...</p>
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
          
          <div class="mt-10 flex gap-4">
            <button
              type="button"
              @click="router.push('/MyEventsPage')"
              class="flex-1 py-3 px-4 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button 
              :disabled="submitting" 
              type="submit" 
              class="flex-1 py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-violet-600 hover:bg-violet-700 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {{ submitting ? 'Updating...' : 'Update Event' }}
            </button>
          </div>
        </form>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
            <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-semibold text-gray-900">Delete Event</h3>
            <p class="text-sm text-gray-500">This action cannot be undone</p>
          </div>
        </div>
        
        <p class="text-gray-700 mb-6">
          Are you sure you want to delete this event? All bookings and participant data will be lost.
        </p>
        
        <div class="flex gap-3">
          <button
            type="button"
            @click="closeDeleteModal"
            class="flex-1 py-2 px-4 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="confirmDelete"
            class="flex-1 py-2 px-4 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 transition-colors"
          >
            Delete Event
          </button>
        </div>
      </div>
    </div>
  </div>
</template>