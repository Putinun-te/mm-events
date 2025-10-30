<template>
  <div class="account-pages">
    <!-- Profile Page -->
    <div v-if="currentPage === 'profile'" class="page-content">
      <UserProfile />
    </div>

    <!-- Bookings Page -->
    <div v-if="currentPage === 'bookings'" class="page-content">
      <div class="page-header">
        <h1>My Bookings</h1>
        <p>Manage and track all your event bookings</p>
      </div>

      <div v-if="userBookings.length > 0" class="bookings-grid">
        <div v-for="booking in userBookings" :key="booking.id" class="booking-card">
          <div class="booking-image">
            <img :src="booking.eventImage" :alt="booking.eventName" />
            <span v-if="booking.status === 'upcoming'" class="badge badge-upcoming">Upcoming</span>
            <span v-else-if="booking.status === 'past'" class="badge badge-past">Past</span>
            <span v-else-if="booking.status === 'cancelled'" class="badge badge-cancelled">Cancelled</span>
          </div>
          <div class="booking-info">
            <h3>{{ booking.eventName }}</h3>
            <p class="booking-date">
              <i class="icon-calendar"></i>
              {{ formatDate(booking.date) }}
            </p>
            <p class="booking-location">
              <i class="icon-location"></i>
              {{ booking.location }}
            </p>
            <div class="booking-details">
              <span class="ticket-count">{{ booking.tickets }} Ticket(s)</span>
              <span class="booking-price">{{ booking.price }}</span>
            </div>
            <div class="booking-actions">
              <button v-if="booking.status === 'upcoming'" class="btn btn-small btn-primary">
                View Details
              </button>
              <button v-if="booking.status === 'upcoming'" class="btn btn-small btn-danger">
                Cancel Booking
              </button>
            </div>
          </div>
        </div>
      </div>
      <div v-else class="empty-state">
        <i class="icon-calendar-empty"></i>
        <h3>No bookings yet</h3>
        <p>Start booking your favorite events!</p>
        <NuxtLink to="/events" class="btn btn-primary">Browse Events</NuxtLink>
      </div>
    </div>

    <!-- Favorites Page -->
    <div v-if="currentPage === 'favorites'" class="page-content">
      <div class="page-header">
        <h1>Favorite Events</h1>
        <p>Events you've saved for later</p>
      </div>

      <div v-if="favoriteEvents.length > 0" class="favorites-grid">
        <div v-for="event in favoriteEvents" :key="event.id" class="favorite-card">
          <div class="favorite-image">
            <img :src="event.image" :alt="event.name" />
            <button class="btn-heart active" @click="removeFavorite(event.id)">
              <i class="icon-heart-filled"></i>
            </button>
          </div>
          <div class="favorite-info">
            <h3>{{ event.name }}</h3>
            <p class="event-date">{{ formatDate(event.date) }}</p>
            <p class="event-artist">by {{ event.artist }}</p>
            <div class="event-rating">
              <i class="icon-star" v-for="i in 5" :key="i" :class="{ filled: i <= event.rating }"></i>
              <span>({{ event.reviews }} reviews)</span>
            </div>
            <NuxtLink :to="`/events/${event.id}`" class="btn btn-primary">
              View Event
            </NuxtLink>
          </div>
        </div>
      </div>
      <div v-else class="empty-state">
        <i class="icon-heart-empty"></i>
        <h3>No favorite events</h3>
        <p>Start adding events to your favorites!</p>
        <NuxtLink to="/events" class="btn btn-primary">Explore Events</NuxtLink>
      </div>
    </div>

    <!-- Settings Page -->
    <div v-if="currentPage === 'settings'" class="page-content">
      <AccountSettings />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import UserProfile from '@/components/UserProfile.vue'
import AccountSettings from '@/components/AccountSettings.vue'

const route = useRoute()

// Determine current page based on route
const currentPage = computed(() => {
  const path = route.path
  if (path.includes('bookings')) return 'bookings'
  if (path.includes('favorites')) return 'favorites'
  if (path.includes('settings')) return 'settings'
  return 'profile'
})

// Sample data
const userBookings = ref([
  {
    id: '1',
    eventName: 'Taylor Swift - Eras Tour',
    eventImage: 'https://via.placeholder.com/300x200',
    date: new Date('2024-12-15'),
    location: 'MetLife Stadium, New Jersey',
    tickets: 2,
    price: '$599.98',
    status: 'upcoming'
  },
  {
    id: '2',
    eventName: 'Ed Sheeran Live',
    eventImage: 'https://via.placeholder.com/300x200',
    date: new Date('2024-11-20'),
    location: 'Madison Square Garden, NYC',
    tickets: 1,
    price: '$149.99',
    status: 'upcoming'
  },
  {
    id: '3',
    eventName: 'The Weeknd Concert',
    eventImage: 'https://via.placeholder.com/300x200',
    date: new Date('2024-09-10'),
    location: 'Barclays Center, Brooklyn',
    tickets: 3,
    price: '$449.97',
    status: 'past'
  }
])

const favoriteEvents = ref([
  {
    id: '1',
    name: 'Billie Eilish Tour',
    image: 'https://via.placeholder.com/300x200',
    date: new Date('2025-01-20'),
    artist: 'Billie Eilish',
    rating: 5,
    reviews: 234
  },
  {
    id: '2',
    name: 'Coldplay Live',
    image: 'https://via.placeholder.com/300x200',
    date: new Date('2024-12-28'),
    artist: 'Coldplay',
    rating: 5,
    reviews: 189
  },
  {
    id: '3',
    name: 'Ariana Grande Concert',
    image: 'https://via.placeholder.com/300x200',
    date: new Date('2025-02-15'),
    artist: 'Ariana Grande',
    rating: 4,
    reviews: 156
  }
])

// Methods
const formatDate = (date: Date) => {
  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }
  return new Intl.DateTimeFormat('en-US', options).format(date)
}

const removeFavorite = (eventId: string) => {
  favoriteEvents.value = favoriteEvents.value.filter(e => e.id !== eventId)
}
</script>

<style scoped lang="scss">
.account-pages {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 40px;

  h1 {
    font-size: 32px;
    font-weight: 700;
    margin: 0 0 8px;
    color: #1a1a1a;
  }

  p {
    font-size: 16px;
    color: #666;
    margin: 0;
  }
}

// Bookings
.bookings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.booking-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;

  &:hover {
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
    transform: translateY(-4px);
  }
}

.booking-image {
  position: relative;
  height: 180px;
  overflow: hidden;
  background: #f0f0f0;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .badge {
    position: absolute;
    top: 12px;
    right: 12px;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;

    &.badge-upcoming {
      background: #e3f2fd;
      color: #1976d2;
    }

    &.badge-past {
      background: #f5f5f5;
      color: #999;
    }

    &.badge-cancelled {
      background: #ffebee;
      color: #d32f2f;
    }
  }
}

.booking-info {
  padding: 20px;

  h3 {
    font-size: 18px;
    font-weight: 600;
    margin: 0 0 12px;
    color: #1a1a1a;
  }

  p {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 14px;
    color: #666;
    margin: 0 0 8px;

    i {
      color: #667eea;
      font-size: 16px;
    }
  }
}

.booking-details {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  margin: 12px 0;
  border-top: 1px solid #f0f0f0;
  border-bottom: 1px solid #f0f0f0;

  .ticket-count {
    font-size: 14px;
    color: #666;
  }

  .booking-price {
    font-size: 18px;
    font-weight: 700;
    color: #667eea;
  }
}

.booking-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

// Favorites
.favorites-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 24px;
}

.favorite-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;

  &:hover {
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
    transform: translateY(-4px);
  }
}

.favorite-image {
  position: relative;
  height: 200px;
  overflow: hidden;
  background: #f0f0f0;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .btn-heart {
    position: absolute;
    top: 12px;
    right: 12px;
    width: 40px;
    height: 40px;
    background: white;
    border: none;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);

    &:hover {
      transform: scale(1.1);
    }

    i {
      font-size: 20px;
      color: #ddd;

      &.icon-heart-filled {
        color: #ff6b6b;
      }
    }

    &.active {
      background: #ff6b6b;

      i {
        color: white;
      }
    }
  }
}

.favorite-info {
  padding: 16px;

  h3 {
    font-size: 16px;
    font-weight: 600;
    margin: 0 0 8px;
    color: #1a1a1a;
  }

  .event-date {
    font-size: 13px;
    color: #999;
    margin: 0 0 4px;
  }

  .event-artist {
    font-size: 14px;
    color: #666;
    margin: 0 0 12px;
  }

  .event-rating {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 12px;
    font-size: 12px;
    color: #999;

    i {
      font-size: 14px;
      color: #ddd;

      &.filled {
        color: #ffd700;
      }
    }
  }

  a {
    display: inline-block;
    width: 100%;
    text-align: center;
  }
}

// Empty State
.empty-state {
  text-align: center;
  padding: 60px 20px;
  background: white;
  border-radius: 12px;
  border: 2px dashed #f0f0f0;

  i {
    font-size: 64px;
    color: #ddd;
    display: block;
    margin-bottom: 16px;
  }

  h3 {
    font-size: 24px;
    font-weight: 600;
    margin: 0 0 8px;
    color: #1a1a1a;
  }

  p {
    font-size: 15px;
    color: #999;
    margin: 0 0 24px;
  }
}

// Buttons
.btn {
  padding: 10px 16px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  text-decoration: none;
  display: inline-block;

  &.btn-primary {
    background: #667eea;
    color: white;

    &:hover {
      background: #764ba2;
    }
  }

  &.btn-danger {
    background: #ff6b6b;
    color: white;

    &:hover {
      background: #ff5252;
    }
  }

  &.btn-small {
    padding: 8px 12px;
    font-size: 12px;
    flex: 1;
  }
}
</style>
