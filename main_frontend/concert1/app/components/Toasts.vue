<script setup lang="ts">
import { useToast } from '~/composables/useToast'
const { toasts, dismiss } = useToast()
</script>

<template>
  <div class="fixed top-4 right-4 z-50 space-y-3">
    <div v-for="t in toasts" :key="t.id" :class="['px-4 py-3 rounded shadow text-sm',
      t.type === 'success' ? 'bg-green-600 text-white' : t.type === 'error' ? 'bg-red-600 text-white' : 'bg-gray-800 text-white'
    ]">
      <div class="flex items-start gap-3">
        <span>{{ t.message }}</span>
        <button class="opacity-80 hover:opacity-100" @click="dismiss(t.id)">✕</button>
      </div>
    </div>
  </div>
  </template>

<style scoped>
</style>
