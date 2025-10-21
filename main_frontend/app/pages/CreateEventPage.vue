<script setup lang="ts">
import EventForm from '~/components/EventForm.vue'
import { useAuth } from '~/composables/useAuth'
import { useRouter } from 'vue-router'
import { useToast } from '~/composables/useToast'

const { user, loadFromStorage, isLoggedIn } = useAuth()
const { success, error } = useToast()
const router = useRouter()
const submitting = ref(false)

onMounted(() => {
  loadFromStorage()
  if (!isLoggedIn.value) router.push('/LoginPage')
})

async function handleSubmit(form: any) {
  submitting.value = true
  try {
    const token = user.value?.token
    await $fetch('/api/events/json', {
      method: 'POST',
      body: form,
      headers: { Authorization: `Bearer ${token}` }
    })
    success('Event created successfully!')
    router.push('/ProductPage')
  } catch (e: any) {
    error(e?.data?.message || 'Failed to create event')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <EventForm mode="create" :submitting="submitting" @submit="handleSubmit" />
</template>
