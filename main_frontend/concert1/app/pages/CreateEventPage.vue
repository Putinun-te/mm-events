<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'

const router = useRouter()
const { loadFromStorage, isLoggedIn, user } = useAuth()

const step = ref(1)
const isSubmitting = ref(false)
const message = ref('')
const isSuccess = ref(false)

const form = reactive({
  title: '',
  description: '',
  category: '',
  location: '',
  address: '',
  city: '',
  country: '',
  personLimit: '' as string | number,
  phone: '',
  startDate: '',
  startTime: '',
  endDate: '',
  endTime: '',
  ticketPrice: '' as string | number,
})

const categories = ['Music', 'Sports', 'Business', 'Technology', 'Food', 'Art']

onMounted(() => {
  loadFromStorage()
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
  }
})

function buildDateTime(date: string, time: string, fallback: string) {
  if (!date) return ''
  const safeTime = time || fallback
  return `${date}T${safeTime}`
}

async function handleSubmit() {
  message.value = ''
  isSuccess.value = false

  if (!form.title || !form.startDate || !form.endDate) {
    message.value = 'Please provide at least a title, start date, and end date.'
    return
  }

  const token = user.value?.token || localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
  if (!token) {
    router.push('/LoginPage')
    return
  }

  const payload = {
    title: form.title.trim(),
    description: form.description || null,
    category: form.category || null,
    location: form.location || null,
    address: form.address || null,
    city: form.city || null,
    country: form.country || null,
    personLimit: form.personLimit ? Number(form.personLimit) : null,
    phone: form.phone || null,
    startDate: buildDateTime(form.startDate, form.startTime, '09:00:00'),
    endDate: buildDateTime(form.endDate, form.endTime, form.startTime || '18:00:00'),
    ticketPrice: form.ticketPrice ? Number(form.ticketPrice) : null,
  }

  if (!payload.startDate || !payload.endDate) {
    message.value = 'Invalid start or end date.'
    return
  }

  isSubmitting.value = true

  try {
    await $fetch('/api/events', {
      method: 'POST',
      body: payload,
      headers: { Authorization: `Bearer ${token}` },
    })

    isSuccess.value = true
    message.value = 'Event created successfully!'
    step.value = 2
  } catch (error: any) {
    console.error('Create event error', error)
    message.value = error?.statusMessage || error?.data?.message || 'Failed to create event.'
  } finally {
    isSubmitting.value = false
  }
}

function resetForm() {
  Object.assign(form, {
    title: '',
    description: '',
    category: '',
    location: '',
    address: '',
    city: '',
    country: '',
    personLimit: '',
    phone: '',
    startDate: '',
    startTime: '',
    endDate: '',
    endTime: '',
    ticketPrice: '',
  })
  step.value = 1
  isSuccess.value = false
  message.value = ''
}
</script>

<template>
  <div class="bg-white rounded shadow-sm py-12 sm:py-16">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between mb-8">
        <div>
          <p class="text-sm text-indigo-600 font-semibold uppercase tracking-wide">Step {{ step }}</p>
          <h1 class="text-3xl font-bold text-gray-900">Create a New Event</h1>
          <p class="mt-2 text-sm text-gray-500">Fill out the details and publish your event.</p>
        </div>
        <button type="button" class="text-sm font-semibold text-indigo-600 hover:text-indigo-700" @click="router.push('/MyEventsPage')">
          My Events
        </button>
      </div>

      <div v-if="message" :class="['rounded-md p-4 mb-6', isSuccess ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200']">
        {{ message }}
      </div>

      <form @submit.prevent="handleSubmit" class="space-y-10">
        <section>
          <h2 class="text-xl font-semibold text-gray-800">Event Details</h2>
          <p class="mt-2 text-sm text-gray-500">Share what makes your event special.</p>

          <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div class="sm:col-span-2">
              <label class="input-label" for="title">Event name *</label>
              <input v-model="form.title" id="title" type="text" placeholder="e.g. Bangkok Music Festival" class="input-control" required />
            </div>

            <div class="sm:col-span-2">
              <label class="input-label" for="description">Description</label>
              <textarea v-model="form.description" id="description" rows="4" placeholder="Give attendees a reason to join" class="input-control textarea"></textarea>
            </div>

            <div>
              <label class="input-label" for="category">Category</label>
              <select v-model="form.category" id="category" class="input-control">
                <option value="">Select category</option>
                <option v-for="option in categories" :key="option" :value="option">{{ option }}</option>
              </select>
            </div>

            <div>
              <label class="input-label" for="ticketPrice">Ticket price</label>
              <input v-model="form.ticketPrice" id="ticketPrice" type="number" min="0" step="0.01" placeholder="0.00" class="input-control" />
            </div>

            <div>
              <label class="input-label" for="personLimit">Capacity</label>
              <input v-model="form.personLimit" id="personLimit" type="number" min="0" placeholder="Number of attendees" class="input-control" />
            </div>

            <div>
              <label class="input-label" for="phone">Contact phone</label>
              <input v-model="form.phone" id="phone" type="tel" placeholder="Contact number" class="input-control" />
            </div>
          </div>
        </section>

        <section>
          <h2 class="text-xl font-semibold text-gray-800">Date & Time</h2>
          <p class="mt-2 text-sm text-gray-500">Let attendees know when the event happens.</p>

          <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <label class="input-label" for="startDate">Start date *</label>
              <input v-model="form.startDate" id="startDate" type="date" class="input-control" required />
            </div>
            <div>
              <label class="input-label" for="startTime">Start time</label>
              <input v-model="form.startTime" id="startTime" type="time" class="input-control" />
            </div>
            <div>
              <label class="input-label" for="endDate">End date *</label>
              <input v-model="form.endDate" id="endDate" type="date" class="input-control" required />
            </div>
            <div>
              <label class="input-label" for="endTime">End time</label>
              <input v-model="form.endTime" id="endTime" type="time" class="input-control" />
            </div>
          </div>
        </section>

        <section>
          <h2 class="text-xl font-semibold text-gray-800">Location</h2>
          <p class="mt-2 text-sm text-gray-500">Share where the event takes place.</p>

          <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div class="sm:col-span-2">
              <label class="input-label" for="location">Venue name</label>
              <input v-model="form.location" id="location" type="text" placeholder="Venue or platform" class="input-control" />
            </div>
            <div class="sm:col-span-2">
              <label class="input-label" for="address">Address</label>
              <input v-model="form.address" id="address" type="text" placeholder="Street, district" class="input-control" />
            </div>
            <div>
              <label class="input-label" for="city">City</label>
              <input v-model="form.city" id="city" type="text" placeholder="City or province" class="input-control" />
            </div>
            <div>
              <label class="input-label" for="country">Country</label>
              <input v-model="form.country" id="country" type="text" placeholder="Country" class="input-control" />
            </div>
          </div>
        </section>

        <div class="flex items-center justify-between pt-6">
          <button type="button" class="text-sm font-semibold text-gray-500 hover:text-gray-700" @click="resetForm" :disabled="isSubmitting">
            Reset form
          </button>
          <button type="submit" class="btn-primary" :disabled="isSubmitting">
            <span v-if="isSubmitting" class="animate-pulse">Publishing…</span>
            <span v-else>Publish event</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.input-label {
  display: block;
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.input-control {
  display: block;
  width: 100%;
  border-radius: 0.375rem;
  border: 1px solid #d1d5db;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  color: #111827;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.input-control:focus {
  outline: none;
  border-color: #4f46e5;
  box-shadow: 0 0 0 1px #4f46e5;
}

.textarea {
  resize: vertical;
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.375rem;
  background-color: #4f46e5;
  padding: 0.5rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: #fff;
  box-shadow: 0 10px 15px -3px rgba(79, 70, 229, 0.3);
  transition: background-color 0.2s ease, transform 0.2s ease, box-shadow 0.2s ease;
}

.btn-primary:hover {
  background-color: #4338ca;
}

.btn-primary:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(129, 140, 248, 0.45);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
