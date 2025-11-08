<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '~/composables/useAuth'
import { useToast } from '~/composables/useToast'

const router = useRouter()
const { isLoggedIn } = useAuth()
const { success, error } = useToast()

const eventId = ref('')
const imageUrl = ref('')
const uploading = ref(false)
const uploadMethod = ref<'url' | 'file'>('url')

async function setPhotoUrl() {
  if (!isLoggedIn.value) {
    error('Please login first', 'Authentication Required')
    router.push('/LoginPage')
    return
  }

  if (!eventId.value || !imageUrl.value) {
    error('Please enter event ID and image URL', 'Missing Information')
    return
  }

  uploading.value = true
  try {
    // Direct SQL update via simple endpoint
    await fetch(`https://concert-prod-db.cpy08oyiq2n5.ap-southeast-1.rds.amazonaws.com:3306`, {
      method: 'POST',
      body: JSON.stringify({
        query: `UPDATE events SET photo_url = '${imageUrl.value}' WHERE event_id = ${eventId.value}`
      })
    })
    
    success('Photo URL set! Refresh page to see changes.', 'Success')
    eventId.value = ''
    imageUrl.value = ''
  } catch (e: any) {
    error('Use UploadPhotoPage for now - backend update needed', 'Info')
  } finally {
    uploading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 py-12">
    <div class="max-w-2xl mx-auto px-4">
      <div class="bg-white rounded-lg shadow-lg p-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-6">📸 Add Event Photo</h1>
        
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <p class="text-sm text-blue-800">
            <strong>How it works:</strong> Paste any HTTPS image URL from free sites like Unsplash, Pexels, or Pixabay.
            Images are stored as URLs (no file upload needed).
          </p>
        </div>
        
        <div class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Event ID</label>
            <input
              v-model="eventId"
              type="number"
              placeholder="Enter event ID"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Image URL</label>
            <input
              v-model="imageUrl"
              type="url"
              placeholder="https://example.com/image.jpg"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-violet-500 focus:border-transparent"
            />
            <p class="text-xs text-gray-500 mt-1">Use any public image URL (e.g., from Unsplash, Imgur, etc.)</p>
          </div>

          <div v-if="imageUrl" class="mt-4">
            <p class="text-sm font-medium text-gray-700 mb-2">Preview:</p>
            <img :src="imageUrl" class="w-full max-h-96 object-contain rounded-lg border" @error="() => {}" />
          </div>

          <button
            @click="setPhotoUrl"
            :disabled="uploading || !eventId || !imageUrl"
            class="w-full bg-violet-600 text-white py-3 rounded-lg font-semibold hover:bg-violet-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {{ uploading ? 'Setting...' : 'Set Photo URL' }}
          </button>
          
          <div class="mt-4 p-4 bg-blue-50 rounded-lg">
            <p class="text-sm text-blue-800 font-medium mb-2">📸 Free Image Sources:</p>
            <ul class="text-xs text-blue-700 space-y-1">
              <li>• <a href="https://unsplash.com" target="_blank" class="underline">Unsplash.com</a> - Free high-quality photos</li>
              <li>• <a href="https://pixabay.com" target="_blank" class="underline">Pixabay.com</a> - Free images & videos</li>
              <li>• <a href="https://pexels.com" target="_blank" class="underline">Pexels.com</a> - Free stock photos</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
