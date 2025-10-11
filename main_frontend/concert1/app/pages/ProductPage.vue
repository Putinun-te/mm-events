<script setup lang="ts">
import { ref,onMounted } from 'vue'
import ProductTag from '~/components/ProductTag.vue';

interface Event {
  id: string;
  name: string;
  datestart: string;
  dateend:string;
  personlimit: number;
  description: string;
}

const eventData = ref<Event[]>([]);

async function fetchCartData() {
  console.log('wow')
  const { data } = await useFetch<Event[]>(`/api/product/data`);

  if (data.value) {
    eventData.value = data.value;
  }  
  else {
    console.log('this is no data')
  }
  console.log(data.value)
  console.log(eventData.value)
}

onMounted(() => {
  fetchCartData()
})

</script>

<template>
  <div class="bg-white rounded shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 md:py-16">
      
      <section class="my-16">
        <div class="text-center">
          <h2 class="text-3xl sm:text-4xl font-bold text-gray-900 tracking-tight">
            Explore Categories
          </h2>
          <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-500">
            Discover events tailored to your interests.
          </p>
        </div>
        
        <div class="mt-12 grid grid-cols-2 sm:grid-cols-2 md:grid-cols-4 gap-6 lg:gap-8">
          <div v-for="i in 4" :key="i">
            <CategoriesTop />
          </div>
        </div>
      </section>
      
      <hr class="border-gray-200" />

      <section class="my-16">
        <div class="text-center">
          <h2 class="text-3xl sm:text-4xl font-bold text-gray-900 tracking-tight">
            Upcomming Events
          </h2>
          <p class="mt-4 max-w-2xl mx-auto text-lg text-gray-500">
            See what's trending and join the excitement.
          </p>
        </div>
        
        <div class="mt-8 mb-12 flex items-center justify-center">
            <ProductTag />
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-8">
          <div v-for="event in eventData" :key="event.id">
            <ProductCard :event="event"/>
          </div>
        </div>
        
        <div class="mt-12 text-center">
          <button class="bg-indigo-600 text-white font-semibold px-6 py-3 rounded-lg shadow-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-300 ease-in-out">
            View All Events
          </button>
        </div>
      </section>
      
    </div>
  </div>
</template>