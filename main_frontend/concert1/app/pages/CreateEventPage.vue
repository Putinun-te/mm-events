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
const { apiFetch } = useApi()

const submitting = ref(false)
const photoUploading = ref(false)
const photoInput = ref<HTMLInputElement | null>(null)
const photoFile = ref<File | null>(null)
const photoPreview = ref<string | null>(null)

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
    
    // Create event in backend
    const backendEvent: any = await apiFetch('/api/events', {
      method: 'POST',
      body: payload,
      headers: { Authorization: `Bearer ${token}` }
    })

    let photoResult: any = null
    if (photoFile.value) {
      const formData = new FormData()
      formData.append('file', photoFile.value)
      photoUploading.value = true
      try {
        photoResult = await apiFetch(`/api/events/${backendEvent?.id}/photo`, {
          method: 'POST',
          body: formData,
          headers: { Authorization: `Bearer ${token}` }
        })
      } catch (uploadErr: any) {
        const uploadMessage = uploadErr?.statusMessage || uploadErr?.data?.message || 'Event created but photo upload failed.'
        error(uploadMessage, 'Photo Upload Failed')
      } finally {
        photoUploading.value = false
      }
    }

    const jsonPayload = {
      backendId: backendEvent?.id,
      id: backendEvent?.id,
      title: backendEvent?.title ?? form.title,
      description: backendEvent?.description ?? form.description,
      personLimit: backendEvent?.personLimit ?? form.personLimit,
      startDate: backendEvent?.startDate ?? payload.startDate,
      endDate: backendEvent?.endDate ?? payload.endDate,
      ticketPrice: backendEvent?.ticketPrice ?? payload.ticketPrice,
      address: backendEvent?.address ?? payload.address,
      city: backendEvent?.city ?? payload.city,
      country: backendEvent?.country ?? payload.country,
      phone: backendEvent?.phone ?? payload.phone,
      category: backendEvent?.category ?? payload.category,
      location: backendEvent?.location ?? payload.location,
      photoUrl: photoResult?.photoUrl ?? backendEvent?.photoUrl ?? null,
      photoId: photoResult?.photoId ?? backendEvent?.photoId ?? null
    }

    try {
      await $fetch('/api/events/json', {
        method: 'POST',
        body: jsonPayload,
        headers: { Authorization: `Bearer ${token}` }
      })
    } catch (syncError: any) {
      console.warn('Event created but JSON sync failed', syncError)
      warning('Event created but catalogue sync failed. Please refresh in a moment.', 'Sync Warning')
    }

    success('Event created successfully!', 'Event Created')
    router.push('/ProductPage')
  } catch (e: any) {
    const message = e?.statusMessage || e?.data?.message || 'Failed to create event.'
    error(message, 'Creation Failed')
  } finally {
    submitting.value = false
  }
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
  if (photoInput.value) {
    photoInput.value.value = ''
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
              <div class="relative w-32 h-32 rounded-full overflow-hidden bg-gray-200 flex items-center justify-center text-gray-400">
                <template v-if="photoPreview">
                  <img :src="photoPreview" alt="Event preview" class="w-full h-full object-cover" />
                  <button type="button" class="absolute top-2 right-2 bg-white bg-opacity-80 rounded-full px-2 py-1 text-xs font-semibold text-gray-700" @click="clearPhoto">
                    ✕
                  </button>
                </template>
                <template v-else>
                  <span class="text-sm text-gray-500">No image selected</span>
                </template>
              </div>
            </div>
            <div class="flex flex-col items-center gap-2">
              <input ref="photoInput" type="file" accept="image/*" class="hidden" @change="handlePhotoChange" />
              <button type="button" class="px-4 py-2 bg-indigo-600 text-white rounded-md text-sm font-medium hover:bg-indigo-700 transition" @click="triggerPhotoSelect" :disabled="photoUploading || submitting">
                {{ photoFile ? 'Change Picture' : 'Upload Picture' }}
              </button>
              <p v-if="photoUploading" class="text-xs text-gray-500">Uploading photo...</p>
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