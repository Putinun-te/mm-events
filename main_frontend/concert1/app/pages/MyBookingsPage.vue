<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { $fetch } from 'ofetch'

interface Booking {
  id: number
  eventId: number
  eventTitle: string
  quantity: number
  totalPrice: number
  status: string
  bookingDate: string
  eventStartDate: string
  eventLocation: string
}

const router = useRouter()
const { loadFromStorage, isLoggedIn } = useAuth()

const bookings = ref<Booking[]>([])
const loading = ref(true)
const message = ref('')

onMounted(async () => {
  loadFromStorage()
  if (!isLoggedIn.value) {
    router.push('/LoginPage')
    return
  }

  await fetchBookings()
})

async function fetchBookings() {
  loading.value = true
  message.value = ''
  try {
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    if (!token) {
      router.push('/LoginPage')
      return
    }
    const res: any = await $fetch('/api/bookings/me', {
      headers: { Authorization: `Bearer ${token}` }
    })
    bookings.value = Array.isArray(res) ? res : []
    if (!bookings.value.length) {
      message.value = 'You have no bookings yet.'
    }
  } catch (error: any) {
    console.error('Load bookings error', error)
    message.value = error?.data?.message || 'Failed to load your bookings.'
  } finally {
    loading.value = false
  }
}

function formatDate(dateStr: string) {
  if (!dateStr) return 'TBA'
  const date = new Date(dateStr)
  return new Intl.DateTimeFormat('en-US', { 
    month: 'short', 
    day: '2-digit', 
    year: 'numeric',
    hour: '2-digit', 
    minute: '2-digit' 
  }).format(date)
}

function goToEvent(booking: Booking) {
  router.push(`/ProductPageDetail/${booking.eventId}`)
}
</script>

<template>
  <div class="main-content container">
    <div class="page-header">
      <h2>My Bookings</h2>
    </div>

    <div v-if="loading" class="empty-state">Loading your bookings...</div>
    <div v-else-if="message" class="empty-state">{{ message }}</div>
    <div v-else class="bookings-grid">
      <div v-for="booking in bookings" :key="booking.id" class="booking-card">
        <div class="booking-header">
          <h3>{{ booking.eventTitle }}</h3>
          <span :class="['status-badge', booking.status.toLowerCase()]">{{ booking.status }}</span>
        </div>
        <div class="booking-details">
          <div class="detail-row">
            <span class="label">📅 Event Date:</span>
            <span>{{ formatDate(booking.eventStartDate) }}</span>
          </div>
          <div class="detail-row">
            <span class="label">📍 Location:</span>
            <span>{{ booking.eventLocation || 'TBA' }}</span>
          </div>
          <div class="detail-row">
            <span class="label">🎫 Tickets:</span>
            <span>{{ booking.quantity }} × ${{ (booking.totalPrice / booking.quantity).toFixed(2) }}</span>
          </div>
          <div class="detail-row">
            <span class="label">💰 Total:</span>
            <span class="total-price">${{ booking.totalPrice.toFixed(2) }}</span>
          </div>
          <div class="detail-row">
            <span class="label">📆 Booked:</span>
            <span>{{ formatDate(booking.bookingDate) }}</span>
          </div>
        </div>
        <button @click="goToEvent(booking)" class="view-event-btn">
          View Event Details
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
.main-content { padding: 20px 0; }
.page-header { margin-bottom: 32px; }
.page-header h2 { font-size: 2rem; font-weight: 600; margin: 0; color: #1a1a1a; }
.empty-state { background: #fff; border: 1px dashed #d1d5db; border-radius: 8px; padding: 24px; text-align: center; color: #6b7280; }

.bookings-grid { 
  display: grid; 
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); 
  gap: 24px; 
}

.booking-card {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  padding: 24px;
  transition: transform 0.2s, box-shadow 0.2s;
}

.booking-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.booking-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e7eb;
}

.booking-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0;
  flex: 1;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
}

.status-badge.confirmed {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.pending {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.cancelled {
  background: #fee2e2;
  color: #991b1b;
}

.booking-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 20px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.95rem;
}

.detail-row .label {
  color: #6b7280;
  font-weight: 500;
}

.total-price {
  font-size: 1.25rem;
  font-weight: 700;
  color: #059669;
}

.view-event-btn {
  width: 100%;
  padding: 12px;
  background: linear-gradient(45deg, #2B293D 0%, #4e4a71 100%);
  color: #fff;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.view-event-btn:hover {
  opacity: 0.9;
}
</style>
