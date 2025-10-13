<script setup lang="ts">
interface Props {
  icon?: string
  title: string
  message: string
  actionText?: string
  actionLink?: string
}

const props = withDefaults(defineProps<Props>(), {
  icon: '📭',
  actionText: 'Get Started'
})
</script>

<template>
  <div class="flex flex-col items-center justify-center py-20 px-4 text-center">
    <div class="text-8xl mb-6 animate-bounce">{{ icon }}</div>
    <h2 class="text-3xl font-bold text-gray-900 mb-3">{{ title }}</h2>
    <p class="text-gray-600 mb-8 max-w-md">{{ message }}</p>
    <NuxtLink v-if="actionLink" :to="actionLink" class="px-8 py-3 bg-gradient-to-r from-purple-600 via-pink-600 to-orange-500 text-white font-bold rounded-lg shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200">
      {{ actionText }}
    </NuxtLink>
    <slot></slot>
  </div>
</template>
