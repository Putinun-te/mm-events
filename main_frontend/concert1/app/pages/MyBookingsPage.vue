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
const cancelling = ref<number | null>(null)
const showCancelModal = ref(false)
const bookingToCancel = ref<Booking | null>(null)

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

function openCancelModal(booking: Booking) {
  bookingToCancel.value = booking
  showCancelModal.value = true
}

function closeCancelModal() {
  showCancelModal.value = false
  bookingToCancel.value = null
}

async function confirmCancelBooking() {
  if (!bookingToCancel.value) return

  const bookingId = bookingToCancel.value.id
  cancelling.value = bookingId

  try {
    const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')
    if (!token) {
      router.push('/LoginPage')
      return
    }

    await $fetch(`/api/bookings/${bookingId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    })

    // Update the booking status locally
    const booking = bookings.value.find(b => b.id === bookingId)
    if (booking) {
      booking.status = 'CANCELLED'
    }

    closeCancelModal()
    message.value = 'Booking cancelled successfully!'
    setTimeout(() => { message.value = '' }, 3000)
  } catch (error: any) {
    console.error('Cancel booking error', error)
    alert(error?.data?.message || 'Failed to cancel booking. Please try again.')
  } finally {
    cancelling.value = null
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
      <p class="text-gray-600 mt-2">Manage all your event bookings in one place</p>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <EventCardSkeleton v-for="n in 6" :key="n" />
    </div>

    <!-- Empty State -->
    <EmptyState
      v-else-if="!bookings.length"
      type="no-bookings"
      title="No bookings yet"
      description="You haven't booked any events yet. Start exploring and book your first event!"
      actionText="Browse Events"
      :actionLink="'/concert/ProductPage'"
    />

    <!-- Bookings Grid -->
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
        <div class="booking-actions">
          <button @click="goToEvent(booking)" class="view-event-btn">
            View Event Details
          </button>
          <button 
            v-if="booking.status === 'CONFIRMED'"
            @click="openCancelModal(booking)" 
            class="cancel-booking-btn"
            :disabled="cancelling === booking.id"
          >
            {{ cancelling === booking.id ? 'Cancelling...' : 'Cancel Booking' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Cancel Confirmation Modal -->
    <div v-if="showCancelModal" class="modal-overlay" @click="closeCancelModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Cancel Booking</h3>
          <button @click="closeCancelModal" class="modal-close">&times;</button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to cancel this booking?</p>
          <div v-if="bookingToCancel" class="booking-summary">
            <p><strong>Event:</strong> {{ bookingToCancel.eventTitle }}</p>
            <p><strong>Tickets:</strong> {{ bookingToCancel.quantity }}</p>
            <p><strong>Total:</strong> ${{ bookingToCancel.totalPrice.toFixed(2) }}</p>
          </div>
          <p class="warning-text">⚠️ This action cannot be undone.</p>
        </div>
        <div class="modal-footer">
          <button @click="closeCancelModal" class="btn-secondary">
            Keep Booking
          </button>
          <button 
            @click="confirmCancelBooking" 
            class="btn-danger"
            :disabled="cancelling !== null"
          >
            {{ cancelling !== null ? 'Cancelling...' : 'Yes, Cancel Booking' }}
          </button>
        </div>
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

.booking-actions {
  display: flex;
  gap: 12px;
  flex-direction: column;
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

.cancel-booking-btn {
  width: 100%;
  padding: 12px;
  background: #fff;
  color: #dc2626;
  border: 2px solid #dc2626;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.cancel-booking-btn:hover:not(:disabled) {
  background: #dc2626;
  color: #fff;
}

.cancel-booking-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: #fff;
  border-radius: 12px;
  max-width: 500px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 2rem;
  color: #6b7280;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: background 0.2s;
}

.modal-close:hover {
  background: #f3f4f6;
}

.modal-body {
  padding: 24px;
}

.modal-body p {
  margin: 0 0 16px 0;
  color: #374151;
  font-size: 1rem;
}

.booking-summary {
  background: #f9fafb;
  border-radius: 8px;
  padding: 16px;
  margin: 16px 0;
}

.booking-summary p {
  margin: 8px 0;
  color: #1f2937;
  font-size: 0.95rem;
}

.booking-summary strong {
  color: #6b7280;
}

.warning-text {
  color: #dc2626;
  font-weight: 600;
  font-size: 0.95rem !important;
  margin-top: 16px !important;
}

.modal-footer {
  padding: 24px;
  border-top: 1px solid #e5e7eb;
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.btn-secondary {
  padding: 10px 20px;
  background: #fff;
  color: #374151;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: #f9fafb;
}

.btn-danger {
  padding: 10px 20px;
  background: #dc2626;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-danger:hover:not(:disabled) {
  background: #b91c1c;
}

.btn-danger:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
