<script setup>
import { ref } from 'vue'
const isMenuOpen = ref(false)
</script>

<template>
  <header class="bg-[#2B293D] text-white sticky top-0 z-40">
    <nav class="container mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between py-4">
      <NuxtLink to="/" class="text-2xl font-bold">MORNINGMORES</NuxtLink>

      <div class="hidden md:flex items-center gap-6">
        <ul class="flex items-center gap-6 font-semibold">
          <li>
            <NuxtLink 
              to="/CreateEventPage" 
              class="px-5 py-2.5 rounded-lg hover:opacity-90 transition-opacity bg-[linear-gradient(45deg,#2B293D,#4e4a71)]"
            >
              Create Event
            </NuxtLink>
          </li>
          <li><NuxtLink to="/ProductPage" class="hover:text-blue-300">My Events</NuxtLink></li>
          <li><NuxtLink to="/MyBookingsPage" class="hover:text-blue-300">My Bookings</NuxtLink></li>
          <li>
            <NuxtLink to="/AccountPage" class="flex items-center gap-2 hover:text-blue-300">
              <i class="fa-regular fa-user"></i> Profile
            </NuxtLink>
          </li>
        </ul>
      </div>
      
      <button @click="isMenuOpen = !isMenuOpen" class="md:hidden text-2xl" aria-label="Toggle Menu">
        <i class="fa-solid fa-bars"></i>
      </button>
    </nav>

    <div v-if="isMenuOpen" class="md:hidden px-4 pb-4 space-y-4 border-t border-white/20">
      <ul class="flex flex-col space-y-2 pt-4 font-semibold">
        <li>
          <NuxtLink 
            to="/CreateEventPage" 
            class="block text-center px-4 py-3 rounded-lg hover:opacity-90 bg-[linear-gradient(45deg,#2B293D,#4e4a71)]"
          >
            Create Event
          </NuxtLink>
        </li>
        <li><NuxtLink to="/my-events" class="block px-4 py-3 rounded-lg hover:bg-white/10">My Events</NuxtLink></li>
        <li><NuxtLink to="/MyBookingsPage" class="block px-4 py-3 rounded-lg hover:bg-white/10">My Bookings</NuxtLink></li>
        <li><NuxtLink to="/AccountPage" class="block px-4 py-3 rounded-lg hover:bg-white/10">Profile</NuxtLink></li>
      </ul>
    </div>
  </header>
</template>