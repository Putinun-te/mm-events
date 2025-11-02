<template>
  <div class="bg-white rounded shadow-sm py-12 sm:py-16">
    <div class="max-w-5xl mx-auto px-6">
      <h1 class="text-3xl sm:text-4xl font-bold text-gray-900">About MM concerts</h1>
      <p class="mt-4 text-gray-600 leading-relaxed">
        MM concerts is a demo platform for discovering and creating events. This page is a simple placeholder you can extend with your team, mission and contact details.
      </p>

      <div class="mt-10 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="p-6 bg-gray-50 rounded-xl">
          <h3 class="font-semibold text-gray-800">Discover</h3>
          <p class="mt-2 text-gray-600 text-sm">Browse upcoming events and find what matches your interests.</p>
        </div>
        <div class="p-6 bg-gray-50 rounded-xl">
          <h3 class="font-semibold text-gray-800">Create</h3>
          <p class="mt-2 text-gray-600 text-sm">Host your own event and manage tickets and attendees.</p>
        </div>
        <div class="p-6 bg-gray-50 rounded-xl">
          <h3 class="font-semibold text-gray-800">Connect</h3>
          <p class="mt-2 text-gray-600 text-sm">Stay in touch with your audience and build your community.</p>
        </div>
      </div>

      <div class="mt-12">
        <!-- ContactPage doesn't exist yet, commenting out for now -->
        <!-- <NuxtLink to="/ContactPage" class="inline-block bg-indigo-600 text-white px-5 py-2 rounded-md font-medium hover:bg-indigo-700">Contact us</NuxtLink> -->
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
</script>