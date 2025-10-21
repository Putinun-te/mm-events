<script setup>
import { ref } from 'vue';

const activeFilter = ref('All');
const filters = ['All', 'Today', 'Tomorrow', 'This Weekend', 'Free'];
</script>

<template>
  <section class="bg-gray-50 py-16">
    <div class="container mx-auto px-4 sm:px-6 lg:px-8">
      <h2 class="text-3xl md:text-4xl font-bold mb-8">Popular Events</h2>
      
      <div class="flex gap-2 md:gap-4 mb-8 overflow-x-auto pb-2 -mx-4 px-4">
        <button
          v-for="filter in filters"
          :key="filter"
          @click="activeFilter = filter"
          class="px-5 py-2 rounded-full font-semibold text-sm transition-colors whitespace-nowrap"
          :class="activeFilter === filter ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-200 border'"
        >
          {{ filter }}
        </button>
      </div>
      
      <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
        <div class="bg-white rounded-xl shadow-lg p-5 flex flex-col gap-4 border border-gray-200/80">
          <div class="flex justify-between items-center">
            <span class="bg-blue-500 text-white text-xs font-semibold px-3 py-1 rounded-full">Travel & Adventure</span>
            <button class="text-gray-400 hover:text-blue-500 text-2xl"><i class="fa-regular fa-star"></i></button>
          </div>
          <div class="flex gap-5 pt-4 border-t">
            <div class="text-center text-blue-600 shrink-0">
              <span class="text-sm font-semibold">NOV</span>
              <span class="text-3xl font-bold block leading-none">25-26</span>
            </div>
            <div class="details">
              <h3 class="text-lg font-bold">Lakeside Camping</h3>
              <p class="text-sm text-gray-500 mb-1">Adventure Geek - Explore the Unexplore..</p>
              <p class="text-sm text-gray-500 font-medium"><i class="fa-solid fa-star text-yellow-400"></i> 14 Interested</p>
            </div>
          </div>
        </div>
        </div>

      <div class="text-center mt-12">
        <button class="bg-white border-2 border-gray-300 px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors">
          See More
        </button>
      </div>
    </div>
  </section>
</template>