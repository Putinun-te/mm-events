<script setup lang="ts">
import { reactive, ref, computed, watch } from 'vue'
import { useToast } from '~/composables/useToast'

interface EventFormData {
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

const props = defineProps<{
  mode: 'create' | 'edit'
  initialData?: Partial<EventFormData>
  submitting?: boolean
}>()

const emit = defineEmits(['submit', 'delete'])
const { error } = useToast()

const step = ref(1)
const categories = ['Music', 'Sports', 'Tech', 'Art', 'Food', 'Business', 'Other']

const form = reactive<EventFormData>({
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

watch(
  () => props.initialData,
  (data) => {
    if (data) Object.assign(form, data)
  },
  { immediate: true }
)

const startISO = computed(() => form.dateStart && form.timeStart ? `${form.dateStart}T${form.timeStart}:00` : '')
const endISO = computed(() => form.dateEnd && form.timeEnd ? `${form.dateEnd}T${form.timeEnd}:00` : '')

// --- Functions for step navigation ---
function nextStep() {
  if (step.value < 3) step.value++
}
function prevStep() {
  if (step.value > 1) step.value--
}

function validate(): string | null {
  // Only validate fields on the current step
  if (step.value === 1) {
    if (!form.title.trim()) return 'Please fill in the event name.'
    if (!form.category) return 'Please select an event category.' // Category check added
    if (!form.description.trim()) return 'Please add a description.'
  }
  if (step.value === 2) {
    if (!form.dateStart || !form.timeStart) return 'Please select a start date and time.'
    if (!form.dateEnd || !form.timeEnd) return 'Please select an end date and time.'
    const s = new Date(startISO.value)
    const e = new Date(endISO.value)
    if (isNaN(s.getTime()) || isNaN(e.getTime())) return 'Invalid date or time provided.'
    if (e <= s) return 'End time must be after start time.'
  }
  return null
}

// --- NEW: Function to handle validation before proceeding ---
function handleNextStep() {
    const err = validate();
    if (err) {
        // If validation fails, show an error toast and stop.
        error(err, 'Validation Error');
        return;
    }
    // If validation passes, move to the next step.
    nextStep();
}

function handleSubmit() {
  // Run final validation on all fields before submitting
  const finalErr = [
    (step.value = 1, validate()),
    (step.value = 2, validate()),
  ].find(e => e !== null);

  step.value = 3; // Go back to the review step in case user came from there

  if (finalErr) return error(finalErr, 'Validation Error')
  
  emit('submit', { ...form, startISO: startISO.value, endISO: endISO.value })
}
</script>

<template>
  <div class="min-h-screen flex flex-col bg-gray-50">
    <div class="w-full bg-gray-200 h-2 relative">
      <div class="absolute top-0 left-0 h-2 transition-all duration-300" 
           :style="{ width: (step / 3) * 100 + '%', backgroundColor: '#207BFA' }" />
    </div>

    <div class="flex justify-center items-center mt-6 mb-4 space-x-20">
      <div v-for="(label, index) in ['Create', 'Ticketing', 'Review']" :key="index" class="flex flex-col items-center">
        <div
          :class="[
            'w-6 h-6 rounded-full border-2 flex items-center justify-center text-xs font-bold',
            step >= index + 1 ? 'bg-[#207BFA] text-white border-[#207BFA]' : 'bg-white border-gray-300 text-gray-400'
          ]">
          {{ index + 1 }}
        </div>
        <span class="mt-2 text-sm" :class="step >= index + 1 ? 'text-[#207BFA]' : 'text-gray-400'">{{ label }}</span>
      </div>
    </div>

    <form @submit.prevent="handleSubmit" class="w-full max-w-2xl mx-auto bg-white rounded-xl shadow-lg p-8 mb-10">
      <div v-if="step === 1">
        <h1 class="text-3xl font-bold text-gray-900 mb-6">{{ mode === 'edit' ? 'Edit Event' : 'Create Event' }}</h1>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Event Name</label>
            <input v-model="form.title" type="text" class="w-full mt-1 p-2 border rounded-md" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Description</label>
            <textarea v-model="form.description" class="w-full mt-1 p-2 border rounded-md"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Category</label>
            <div class="flex flex-wrap gap-2 mt-2">
              <button
                v-for="cat in categories"
                :key="cat"
                type="button"
                @click="form.category = cat"
                :class="[
                  'px-3 py-1 rounded-full text-sm',
                  form.category === cat ? 'bg-[#207BFA] text-white' : 'bg-gray-100 hover:bg-gray-200'
                ]">
                {{ cat }}
              </button>
            </div>
          </div>
        </div>
        <div class="mt-8 flex justify-end">
          <button @click="handleNextStep" type="button" class="bg-[#207BFA] text-white px-6 py-2 rounded-md hover:bg-blue-600">
            Next
          </button>
        </div>
      </div>

      <div v-else-if="step === 2">
        <h1 class="text-3xl font-bold text-gray-900 mb-6">Ticketing & Schedule</h1>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Person Limit</label>
            <input v-model.number="form.personLimit" type="number" class="w-full mt-1 p-2 border rounded-md" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Ticket Price</label>
            <input v-model.number="form.ticketPrice" type="number" class="w-full mt-1 p-2 border rounded-md" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Start Date</label>
              <input v-model="form.dateStart" type="date" class="w-full mt-1 p-2 border rounded-md" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Start Time</label>
              <input v-model="form.timeStart" type="time" class="w-full mt-1 p-2 border rounded-md" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">End Date</label>
              <input v-model="form.dateEnd" type="date" class="w-full mt-1 p-2 border rounded-md" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">End Time</label>
              <input v-model="form.timeEnd" type="time" class="w-full mt-1 p-2 border rounded-md" />
            </div>
          </div>
        </div>
        <div class="mt-8 flex justify-between">
          <button @click="prevStep" type="button" class="px-6 py-2 border rounded-md">Back</button>
          <button @click="handleNextStep" type="button" class="bg-[#207BFA] text-white px-6 py-2 rounded-md">Next</button>
        </div>
      </div>

      <div v-else-if="step === 3">
        <h1 class="text-3xl font-bold text-gray-900 mb-6">Review & Submit</h1>
        <div class="space-y-3 text-gray-700 bg-gray-50 p-6 rounded-lg">
          <p><strong>Title:</strong> {{ form.title }}</p>
          <p><strong>Description:</strong> {{ form.description }}</p>
          <p><strong>Category:</strong> {{ form.category || '—' }}</p>
          <p><strong>Person Limit:</strong> {{ form.personLimit || '—' }}</p>
          <p><strong>Ticket Price:</strong> {{ form.ticketPrice ? `$${form.ticketPrice}` : 'Free' }}</p>
          <hr class="my-3 border-gray-300" />
          <p><strong>Event Schedule:</strong></p>
          <div class="ml-4 space-y-1">
            <p><strong>Start:</strong> {{ form.dateStart || '—' }} {{ form.timeStart }}</p>
            <p><strong>End:</strong> {{ form.dateEnd || '—' }} {{ form.timeEnd }}</p>
          </div>
        </div>
        <div class="mt-8 flex justify-between items-center">
          <button @click="prevStep" type="button" class="px-6 py-2 border rounded-md">Back</button>
          <div class="flex gap-4">
            <button v-if="mode === 'edit'" type="button" @click="emit('delete')" class="px-6 py-2 bg-red-600 text-white rounded-md hover:bg-red-700">Delete</button>
            <button type="submit" :disabled="props.submitting" class="bg-[#207BFA] text-white px-6 py-2 rounded-md hover:bg-blue-600 disabled:opacity-60">
              {{ props.submitting ? 'Saving...' : (mode === 'edit' ? 'Update Event' : 'Create Event') }}
            </button>
          </div>
        </div>
      </div>
    </form>
  </div>
</template>