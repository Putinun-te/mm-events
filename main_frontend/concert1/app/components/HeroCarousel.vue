<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

interface FeaturedEvent {
  id: string
  title: string
  subtitle: string
  image: string
  date: string
  time: string
  location: string
  ctaText: string
  ctaLink: string
  category: string
  badge?: string
}

const props = defineProps<{
  events: FeaturedEvent[]
  autoRotate?: boolean
  interval?: number
}>()

const currentIndex = ref(0)
let intervalId: NodeJS.Timeout | null = null

const nextSlide = () => {
  currentIndex.value = (currentIndex.value + 1) % props.events.length
}

const prevSlide = () => {
  currentIndex.value = (currentIndex.value - 1 + props.events.length) % props.events.length
}

const goToSlide = (index: number) => {
  currentIndex.value = index
}

onMounted(() => {
  if (props.autoRotate !== false) {
    intervalId = setInterval(nextSlide, props.interval || 5000)
  }
})

onUnmounted(() => {
  if (intervalId) clearInterval(intervalId)
})

const pauseAutoRotate = () => {
  if (intervalId) {
    clearInterval(intervalId)
    intervalId = null
  }
}

const resumeAutoRotate = () => {
  if (props.autoRotate !== false && !intervalId) {
    intervalId = setInterval(nextSlide, props.interval || 5000)
  }
}
</script>

<template>
  <div class="relative w-full h-[500px] md:h-[600px] lg:h-[700px] overflow-hidden bg-black" @mouseenter="pauseAutoRotate" @mouseleave="resumeAutoRotate">
    <TransitionGroup name="carousel">
      <div v-for="(event, index) in events" :key="event.id" v-show="index === currentIndex" class="absolute inset-0">
        <div class="relative w-full h-full">
          <img :src="event.image" :alt="event.title" class="w-full h-full object-cover opacity-70" />
          <div class="absolute inset-0 bg-gradient-to-t from-black via-black/50 to-transparent"></div>
          
          <div class="absolute inset-0 flex items-center justify-center">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
              <div v-if="event.badge" class="mb-4">
                <span class="inline-block px-6 py-2 bg-red-600 text-white font-bold text-sm uppercase tracking-wider rounded-full animate-pulse">
                  {{ event.badge }}
                </span>
              </div>
              
              <div class="mb-4">
                <span class="inline-block px-4 py-2 bg-purple-600/80 backdrop-blur-sm text-white text-sm font-semibold rounded-full">
                  {{ event.category }}
                </span>
              </div>
              
              <h1 class="text-5xl md:text-7xl lg:text-8xl font-bold text-white mb-4 drop-shadow-2xl animate-fade-in">
                {{ event.title }}
              </h1>
              
              <p class="text-xl md:text-2xl text-gray-200 mb-6 max-w-3xl mx-auto drop-shadow-lg">
                {{ event.subtitle }}
              </p>
              
              <div class="flex flex-wrap items-center justify-center gap-4 text-white mb-8">
                <div class="flex items-center gap-2">
                  <span class="text-2xl">📅</span>
                  <span class="font-semibold">{{ event.date }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-2xl">🕐</span>
                  <span class="font-semibold">{{ event.time }}</span>
                </div>
                <div class="flex items-center gap-2">
                  <span class="text-2xl">📍</span>
                  <span class="font-semibold">{{ event.location }}</span>
                </div>
              </div>
              
              <NuxtLink :to="event.ctaLink" class="inline-block px-12 py-4 bg-gradient-to-r from-pink-600 via-purple-600 to-indigo-600 text-white text-xl font-bold rounded-full shadow-2xl hover:shadow-pink-500/50 transform hover:scale-105 transition-all duration-300">
                {{ event.ctaText }} →
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </TransitionGroup>

    <button @click="prevSlide" class="absolute left-4 top-1/2 transform -translate-y-1/2 bg-white/20 hover:bg-white/40 backdrop-blur-md text-white p-4 rounded-full transition-all duration-300 z-10" aria-label="Previous slide">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M15 19l-7-7 7-7" />
      </svg>
    </button>

    <button @click="nextSlide" class="absolute right-4 top-1/2 transform -translate-y-1/2 bg-white/20 hover:bg-white/40 backdrop-blur-md text-white p-4 rounded-full transition-all duration-300 z-10" aria-label="Next slide">
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M9 5l7 7-7 7" />
      </svg>
    </button>

    <div class="absolute bottom-8 left-1/2 transform -translate-x-1/2 flex gap-3 z-10">
      <button v-for="(event, index) in events" :key="`dot-${index}`" @click="goToSlide(index)" :class="['w-3 h-3 rounded-full transition-all duration-300', index === currentIndex ? 'bg-white w-12' : 'bg-white/50 hover:bg-white/80']" :aria-label="`Go to slide ${index + 1}`"></button>
    </div>
  </div>
</template>

<style scoped>
.carousel-enter-active,
.carousel-leave-active {
  transition: opacity 1s ease, transform 1s ease;
}

.carousel-enter-from {
  opacity: 0;
  transform: scale(1.1);
}

.carousel-leave-to {
  opacity: 0;
  transform: scale(0.95);
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
