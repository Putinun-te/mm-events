<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

interface Event {
  id: string
  name: string
  datestart: string
  dateend: string
  personlimit: number
  registeredCount?: number
  location?: string
  status: 'upcoming' | 'past' | 'cancelled'
  category?: string
}

const events = ref<Event[]>([])
const isLoading = ref(true)
const searchQuery = ref('')
const statusFilter = ref<'all' | 'upcoming' | 'past' | 'cancelled'>('all')
const currentPage = ref(1)
const itemsPerPage = 10

const showParticipantsModal = ref(false)
const showDeleteConfirmModal = ref(false)
const selectedEvent = ref<Event | null>(null)
const selectedEventParticipants = ref<string[]>([])

const fetchEvents = async () => {
  isLoading.value = true
  try {
    const { data } = await useFetch<Event[]>('/api/product/data')
    if (data.value) {
      events.value = data.value.map(e => ({
        ...e,
        status: determineStatus(e)
      }))
    }
  } catch (error) {
    console.error('Failed to fetch events:', error)
  } finally {
    isLoading.value = false
  }
}

const determineStatus = (event: Event): 'upcoming' | 'past' | 'cancelled' => {
  const now = Date.now() / 1000
  if (parseInt(event.datestart) > now) return 'upcoming'
  return 'past'
}

const filteredEvents = computed(() => {
  let filtered = events.value

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(e =>
      e.name.toLowerCase().includes(query) ||
      e.location?.toLowerCase().includes(query)
    )
  }

  if (statusFilter.value !== 'all') {
    filtered = filtered.filter(e => e.status === statusFilter.value)
  }

  return filtered
})

const paginatedEvents = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  const end = start + itemsPerPage
  return filteredEvents.value.slice(start, end)
})

const totalPages = computed(() =>
  Math.ceil(filteredEvents.value.length / itemsPerPage)
)

const formatDate = (timestamp: string) => {
  return new Date(parseInt(timestamp) * 1000).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const getStatusBadge = (status: string) => {
  const badges = {
    upcoming: { text: 'Upcoming', class: 'bg-green-100 text-green-800' },
    past: { text: 'Past', class: 'bg-gray-100 text-gray-800' },
    cancelled: { text: 'Cancelled', class: 'bg-red-100 text-red-800' }
  }
  return badges[status as keyof typeof badges] || badges.upcoming
}

const viewParticipants = (event: Event) => {
  selectedEvent.value = event
  selectedEventParticipants.value = [
    'john.doe@example.com',
    'jane.smith@example.com',
    'mike.johnson@example.com'
  ]
  showParticipantsModal.value = true
}

const editEvent = (eventId: string) => {
  navigateTo(`/concert/CreateEventPage?edit=${eventId}`)
}

const confirmDelete = (event: Event) => {
  selectedEvent.value = event
  showDeleteConfirmModal.value = true
}

const deleteEvent = async () => {
  if (!selectedEvent.value) return
  
  try {
    console.log('Deleting event:', selectedEvent.value.id)
    events.value = events.value.filter(e => e.id !== selectedEvent.value?.id)
    showDeleteConfirmModal.value = false
    selectedEvent.value = null
  } catch (error) {
    console.error('Failed to delete event:', error)
  }
}

onMounted(() => {
  fetchEvents()
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-purple-50 p-6">
    <div class="max-w-7xl mx-auto">
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 mb-2">Event Management</h1>
        <p class="text-gray-600">Manage all events, participants, and settings</p>
      </div>

      <div class="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden">
        <div class="p-6 border-b border-gray-200">
          <div class="flex flex-col lg:flex-row gap-4 items-center justify-between">
            <div class="w-full lg:w-96">
              <div class="relative">
                <span class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 text-xl">🔍</span>
                <input v-model="searchQuery" type="text" placeholder="Search by event name or location..." class="w-full pl-11 pr-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent" />
              </div>
            </div>

            <div class="flex gap-2">
              <button v-for="status in ['all', 'upcoming', 'past', 'cancelled']" :key="status" @click="statusFilter = status as any" :class="{'bg-purple-600 text-white': statusFilter === status, 'bg-gray-100 text-gray-700 hover:bg-gray-200': statusFilter !== status}" class="px-4 py-2 rounded-lg font-medium transition-all capitalize">
                {{ status }}
              </button>
            </div>

            <NuxtLink to="/concert/CreateEventPage" class="px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition-all whitespace-nowrap">
              + Create Event
            </NuxtLink>
          </div>
        </div>

        <div v-if="isLoading" class="p-12 text-center">
          <LoadingSpinner />
          <p class="text-gray-500 mt-4">Loading events...</p>
        </div>

        <div v-else-if="filteredEvents.length === 0" class="p-12 text-center">
          <div class="text-6xl mb-4">📭</div>
          <h3 class="text-xl font-bold text-gray-900 mb-2">No events found</h3>
          <p class="text-gray-600 mb-6">Try adjusting your search or filters</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50 border-b border-gray-200">
              <tr>
                <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Event Name</th>
                <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Date</th>
                <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Capacity</th>
                <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Registered</th>
                <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Status</th>
                <th class="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="event in paginatedEvents" :key="event.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                  <div class="font-semibold text-gray-900">{{ event.name }}</div>
                  <div v-if="event.location" class="text-sm text-gray-500">📍 {{ event.location }}</div>
                </td>
                <td class="px-6 py-4 text-sm text-gray-700">
                  {{ formatDate(event.datestart) }}
                </td>
                <td class="px-6 py-4 text-sm font-semibold text-gray-900">
                  {{ event.personlimit }}
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-semibold text-purple-600">{{ event.registeredCount || 0 }}</span>
                    <span class="text-sm text-gray-500">/ {{ event.personlimit }}</span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span :class="getStatusBadge(event.status).class" class="px-3 py-1 rounded-full text-xs font-semibold">
                    {{ getStatusBadge(event.status).text }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex gap-2">
                    <button @click="viewParticipants(event)" class="px-3 py-1.5 bg-blue-100 hover:bg-blue-200 text-blue-700 text-sm font-medium rounded-lg transition-all" title="View Participants">
                      👥 Participants
                    </button>
                    <button @click="editEvent(event.id)" class="px-3 py-1.5 bg-purple-100 hover:bg-purple-200 text-purple-700 text-sm font-medium rounded-lg transition-all" title="Edit Event">
                      ✏️
                    </button>
                    <button @click="confirmDelete(event)" class="px-3 py-1.5 bg-red-100 hover:bg-red-200 text-red-700 text-sm font-medium rounded-lg transition-all" title="Delete Event">
                      🗑️
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-if="totalPages > 1" class="p-6 border-t border-gray-200 flex items-center justify-between">
          <div class="text-sm text-gray-600">
            Showing {{ (currentPage - 1) * itemsPerPage + 1 }} to {{ Math.min(currentPage * itemsPerPage, filteredEvents.length) }} of {{ filteredEvents.length }} events
          </div>
          <div class="flex gap-2">
            <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage === 1" class="px-4 py-2 border-2 border-gray-300 rounded-lg font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all">
              Previous
            </button>
            <button @click="currentPage = Math.min(totalPages, currentPage + 1)" :disabled="currentPage === totalPages" class="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-all">
              Next
            </button>
          </div>
        </div>
      </div>
    </div>

    <Modal :show="showParticipantsModal" :title="`Participants - ${selectedEvent?.name}`" confirmText="Close" @confirm="showParticipantsModal = false" @cancel="showParticipantsModal = false" @close="showParticipantsModal = false">
      <div class="space-y-2">
        <p class="text-sm text-gray-600 mb-4">{{ selectedEventParticipants.length }} registered participant(s)</p>
        <div v-for="(email, index) in selectedEventParticipants" :key="index" class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
          <div class="w-10 h-10 bg-gradient-to-br from-purple-400 to-pink-400 rounded-full flex items-center justify-center text-white font-bold">
            {{ email[0].toUpperCase() }}
          </div>
          <span class="text-gray-700 font-medium">{{ email }}</span>
        </div>
      </div>
    </Modal>

    <Modal :show="showDeleteConfirmModal" title="Delete Event" confirmText="Delete" cancelText="Cancel" confirmColor="bg-red-600 hover:bg-red-700" @confirm="deleteEvent" @cancel="showDeleteConfirmModal = false" @close="showDeleteConfirmModal = false">
      <div class="space-y-4">
        <div class="flex items-center gap-3 p-4 bg-red-50 border-l-4 border-red-500 rounded">
          <span class="text-3xl">⚠️</span>
          <div>
            <p class="font-semibold text-red-900">Are you sure you want to delete this event?</p>
            <p class="text-sm text-red-700 mt-1">This action cannot be undone.</p>
          </div>
        </div>
        <div v-if="selectedEvent" class="p-4 bg-gray-50 rounded-lg">
          <p class="font-semibold text-gray-900">{{ selectedEvent.name }}</p>
          <p class="text-sm text-gray-600">{{ selectedEvent.registeredCount || 0 }} registered participants will be notified</p>
        </div>
      </div>
    </Modal>
  </div>
</template>
