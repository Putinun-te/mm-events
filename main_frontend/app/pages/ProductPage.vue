<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { $fetch } from 'ofetch'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useUnauthorizedHandler } from '~/composables/useUnauthorizedHandler'

type MyEvent = any

const router = useRouter()
const { loadFromStorage, isLoggedIn, user } = useAuth()
const { handleApiError } = useUnauthorizedHandler()

const events = ref<MyEvent[]>([])
const loading = ref(true)
const message = ref('')

onMounted(async () => {
  loadFromStorage()
  
  // ===============================================
  // --- LOGIN CHECK BYPASSED FOR TESTING ---
  // ===============================================
  
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
    return
  }
  

  await fetchEvents()
})

function toEpochSeconds(dateLike: any): number | null {
  if (!dateLike) return null
  if (typeof dateLike === 'number') return dateLike
  if (typeof dateLike === 'string') {
    const d = new Date(dateLike)
    if (!isNaN(d.getTime())) return Math.floor(d.getTime() / 1000)
  }
  return null
}

function formatRange(event: MyEvent) {
  const startSec = toEpochSeconds(event.datestart ?? event.startDate)
  const endSec = toEpochSeconds(event.dateend ?? event.endDate) ?? startSec
  if (!startSec) return 'Schedule coming soon'
  const start = new Date(startSec * 1000)
  const end = endSec ? new Date(endSec * 1000) : start
  const dateFormatter = new Intl.DateTimeFormat('en-US', { month: 'short', day: '2-digit' })
  const timeFormatter = new Intl.DateTimeFormat('en-US', { hour: '2-digit', minute: '2-digit' })

  const sameDay = start.toDateString() === end.toDateString()
  const datePart = sameDay
    ? dateFormatter.format(start)
    : `${dateFormatter.format(start)} - ${dateFormatter.format(end)}`

  return `${datePart} | ${timeFormatter.format(start)} - ${timeFormatter.format(end)}`
}

async function fetchEvents() {
  loading.value = true
  message.value = ''

  // ===============================================
  // --- FAKE DATA FOR TESTING ---
  // ===============================================
  /*
  // 1. Simulate a network delay
  await new Promise(resolve => setTimeout(resolve, 1000));

  // 2. Create sample event data
  
  const fakeEvents: MyEvent[] = [
    {
      id: 1,
      title: 'My First Awesome Event',
      startDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(), // 5 days from now
      endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000 + 3 * 60 * 60 * 1000).toISOString(), // 3 hours later
      city: 'Bangkok'
    },
    {
      id: 2,
      name: 'Another Cool Meetup',
      datestart: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
      dateend: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000).toISOString(),
      address: 'Chiang Mai, Thailand'
    },
    {
      id: 3,
      title: 'Past Workshop',
      startDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
      endDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000 + 4 * 60 * 60 * 1000).toISOString(),
      city: 'Phuket'
    }
  ];
  
  // 3. Assign the fake data and stop loading
  events.value = fakeEvents;
  loading.value = false;
  */

  // ===============================================
  // --- ORIGINAL API CALL (COMMENTED OUT) ---
  // ===============================================
  try {
    const token = user.value?.token || localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    if (!token) {
      return
    }
    const res: any = await $fetch('/api/events/json/me', {
      headers: { Authorization: `Bearer ${token}` }
    })
    events.value = Array.isArray(res) ? res : []
    if (!events.value.length) {
      message.value = 'You have not created any events yet.'
    }
  } catch (error: any) {
    console.error('Load my events error', error)
    
    if (handleApiError(error, '/MyEventsPage')) {
      return
    }
    
    message.value = error?.data?.message || error?.response?._data?.message || 'Failed to load your events.'
  } finally {
    loading.value = false
  }

}function goToEvent(event: MyEvent) {
  console.log('Navigating to event:', event.id)
  router.push({ path: `/EditEventPage`, query: { id: event.id } })
}
</script>

<template>
  <div class="main-content container">
    <div class="page-header">
      <h2>My Events</h2>
      </div>

    <div v-if="loading" class="empty-state">Loading your events...</div>
    <div v-else-if="message" class="empty-state">{{ message }}</div>
    <div v-else class="user-event-list">
      <button v-for="event in events" :key="event.id" type="button" class="user-event-card" @click="goToEvent(event)">
        <div class="event-info">
          <h3>{{ event.name || event.title }}</h3>
          <p>{{ formatRange(event) }}</p>
          <p class="event-location" v-if="event.city || event.address">{{ event.city || event.address }}</p>
        </div>
        <div class="event-status">
          <span class="status-tag">Published</span>
          <i class="fa-solid fa-chevron-right"></i>
        </div>
      </button>
    </div>
  </div>
</template>

<style scoped>
.container { 
  max-width: 1200px; 
  margin: 0 auto; 
  padding: 0 20px; 
}
.main-content { 
  padding: 40px 0; 
  /* ADDED: These properties make the content area expand to fill empty space */
  flex-grow: 1;
  display: flex;
  flex-direction: column;
}
.page-header { 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  margin-bottom: 24px; 
}
.page-header h2 { 
  font-size: 2rem; 
  font-weight: 600; 
  margin: 0; 
}
/* REMOVED: The .btn-create style is no longer needed. */
.user-event-list { 
  display: grid; 
  gap: 16px; 
}
.user-event-card { 
  background: #fff; 
  border-radius: 8px; 
  border: 1px solid #EAEAEA; 
  box-shadow: 0 4px 12px rgba(0,0,0,0.05); 
  padding: 16px; 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  text-decoration: none; 
  color: #333; 
  width: 100%; 
  text-align: left; 
  cursor: pointer; 
}
.user-event-card:hover { 
  transform: translateY(-2px); 
  transition: .2s; 
}
.event-info h3 { 
  font-size: 1.2rem; 
  margin-bottom: 4px; 
}
.event-info p { 
  color: #666; 
}
.event-status { 
  display: flex; 
  align-items: center; 
  gap: 12px; 
}
.status-tag { 
  background: #28a745; 
  color: #fff; 
  padding: 4px 10px; 
  border-radius: 20px; 
  font-size: 0.8rem; 
  font-weight: 500; 
}
.empty-state { 
  background: #fff; 
  border: 1px dashed #d1d5db; 
  border-radius: 8px; 
  padding: 24px; 
  text-align: center; 
  color: #6b7280; 
}
.event-location { 
  font-size: 0.9rem; 
}
</style>