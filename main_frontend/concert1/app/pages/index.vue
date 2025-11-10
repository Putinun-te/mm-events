<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useApi } from '~/composables/useApi'
import { useImage } from '~/composables/useImage'

const { apiFetch } = useApi()
const { getEventPhotoUrl } = useImage()
const events = ref([])
const loading = ref(true)

const eventImg = new URL('../assets/img/even2.jpg', import.meta.url).href
const event3Img = new URL('../assets/img/event3.jpg', import.meta.url).href

const show = ref(false)
const show2 = ref(false)
const currentSlide = ref(0)

const slides = [
  {
    id: 1,
    title: 'Welcome to MM concerts',
    description: 'Experience unforgettable live music events and exclusive performances',
    buttonText: 'Browse Events',
    link: '/product-page',
    image: event3Img,
    gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
  },
  {
    id: 3,
    title: 'Create Event',
    description: 'Easily plan and promote your event with our powerful tools',
    buttonText: 'Create Now',
    link: '/CreateEventPage',
    // use image for background
    image: eventImg,
    // keep gradient as fallback if needed
    gradient: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)'
  }
]

let intervalId = null

const click = () => {
  show.value = !show.value
  if (show.value) show2.value = false
}

const click2 = () => {
  show2.value = !show2.value
  if (show2.value) show.value = false
}

const nextSlide = () => {
  currentSlide.value = (currentSlide.value + 1) % slides.length
}

const prevSlide = () => {
  currentSlide.value = (currentSlide.value - 1 + slides.length) % slides.length
}

onMounted(async () => {
  intervalId = setInterval(nextSlide, 5000)
  
  try {
    const response = await apiFetch('/api/events')
    events.value = response.content || []
  } catch (error) {
    console.error('Failed to load events:', error)
  } finally {
    loading.value = false
  }
})

onUnmounted(() => {
  if (intervalId) clearInterval(intervalId)
})
</script>

<template>
  <div class="">
    <!-- Navigation Header -->
    
    <!-- Modals -->
    <transition name="fade">
      <div v-if="show" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4" @click.self="show = false">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full transform transition-all" @click.stop>
          <Login @close="show = false" />
        </div>
      </div>
    </transition>

    <transition name="fade">
      <div v-if="show2" class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4" @click.self="show2 = false">
        <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full transform transition-all" @click.stop>
          <Register @close="show2 = false" />
        </div>
      </div>
    </transition>

    <!-- Hero Carousel Section -->
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="relative rounded-3xl overflow-hidden shadow-2xl">
        <!-- Carousel Container -->
        <div class="relative h-[500px] sm:h-[600px]">
          <!-- Slides -->
          <transition-group name="slide">
            <div
              v-for="(slide, index) in slides"
              :key="slide.id"
              v-show="currentSlide === index"
              class="absolute inset-0 w-full h-full"
            >
              <div 
                class="w-full h-full flex items-center justify-center"
                :style="slide.image ? { backgroundImage: `url(${slide.image})`, backgroundSize: 'cover', backgroundPosition: 'center' } : { background: slide.gradient }"
              >
                <div class="text-center text-white px-6 max-w-3xl">
                  <h2 class="text-5xl sm:text-6xl font-bold mb-6 animate-fade-in">
                    {{ slide.title }}
                  </h2>
                  <p class="text-xl sm:text-2xl mb-8 opacity-90">
                    {{ slide.description }}
                  </p>
                  <NuxtLink 
                    :to="slide.link"
                    class="inline-block px-8 py-4 bg-white text-gray-900 rounded-full font-semibold text-lg hover:bg-opacity-90 transform hover:scale-105 transition-all duration-200 shadow-lg"
                  >
                    {{ slide.buttonText }}
                  </NuxtLink>
                </div>
              </div>
            </div>
          </transition-group>

          <!-- Navigation Arrows -->
          <!-- <button 
            @click="prevSlide"
            class="absolute left-4 top-1/2 -translate-y-1/2 bg-white bg-opacity-30 hover:bg-opacity-50 text-white rounded-full p-3 backdrop-blur-sm transition-all duration-200 z-10"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <button 
            @click="nextSlide"
            class="absolute right-4 top-1/2 -translate-y-1/2 bg-white bg-opacity-30 hover:bg-opacity-50 text-white rounded-full p-3 backdrop-blur-sm transition-all duration-200 z-10"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </button> -->

          <!-- Indicators -->
          <div class="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-3 z-10">
            <button
              v-for="(slide, index) in slides"
              :key="slide.id"
              @click="currentSlide = index"
              class="transition-all duration-200"
              :class="currentSlide === index ? 'w-12 bg-white' : 'w-3 bg-white bg-opacity-50 hover:bg-opacity-75'"
              style="height: 12px; border-radius: 6px;"
            />
          </div>
        </div>
      </div>
    </section>

    <!-- Quick Links Section -->
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <NuxtLink 
          to="/product-page"
          class="group relative overflow-hidden rounded-2xl bg-gradient-to-br from-blue-500 to-blue-700 p-8 text-white shadow-xl hover:shadow-2xl transform hover:-translate-y-1 transition-all duration-300"
        >
          <div class="relative z-10">
            <h3 class="text-3xl font-bold mb-3">Browse Events</h3>
            <p class="text-blue-100 mb-4">Discover our amazing events</p>
            <span class="inline-flex items-center text-sm font-semibold">
              Explore Now
              <svg class="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </svg>
            </span>
          </div>
          <div class="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
        </NuxtLink>

        <NuxtLink 
          to="/MyEventsPage"
          class="group relative overflow-hidden rounded-2xl bg-gradient-to-br from-purple-500 to-purple-700 p-8 text-white shadow-xl hover:shadow-2xl transform hover:-translate-y-1 transition-all duration-300"
        >
          <div class="relative z-10">
            <h3 class="text-3xl font-bold mb-3">Your Events</h3>
            <p class="text-purple-100 mb-4">Manage and explore your events</p>
            <span class="inline-flex items-center text-sm font-semibold">
              View Details
              <svg class="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </svg>
            </span>
          </div>
          <div class="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
        </NuxtLink>
      </div>
    </section>

    <!-- Events Listing Section -->
    <section id="events" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="text-center mb-12">
        <h2 class="text-4xl font-bold text-gray-900 mb-4">Upcoming Events</h2>
        <p class="text-xl text-gray-600">Discover amazing concerts and events</p>
      </div>

      <div v-if="loading" class="text-center py-12">
        <p class="text-gray-500">Loading events...</p>
      </div>

      <div v-else-if="events.length === 0" class="text-center py-12">
        <p class="text-gray-500">No events available at the moment.</p>
      </div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <NuxtLink
          v-for="event in events"
          :key="event.id"
          :to="`/ProductPageDetail/${event.id}`"
          class="group bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-2xl transform hover:-translate-y-1 transition-all duration-300"
        >
          <div class="aspect-video overflow-hidden bg-gray-200">
            <img
              :src="getEventPhotoUrl(event.photoUrl)"
              :alt="event.title"
              class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
            />
          </div>
          <div class="p-6">
            <h3 class="text-xl font-bold text-gray-900 mb-2 line-clamp-2">{{ event.title }}</h3>
            <p class="text-gray-600 text-sm mb-4 line-clamp-2">{{ event.description }}</p>
            <div class="flex items-center justify-between">
              <span class="text-2xl font-bold text-green-600">${{ event.ticketPrice || 0 }}</span>
              <span class="text-sm text-gray-500">{{ event.location }}</span>
            </div>
          </div>
        </NuxtLink>
      </div>
    </section>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

.slide-enter-active {
  transition: all 0.6s ease;
}

.slide-leave-active {
  transition: all 0.6s ease;
}

.slide-enter-from {
  transform: translateX(100%);
  opacity: 0;
}

.slide-leave-to {
  transform: translateX(-100%);
  opacity: 0;
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.8s ease-out;
}
</style>