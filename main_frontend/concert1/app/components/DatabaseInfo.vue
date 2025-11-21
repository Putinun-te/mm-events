<template>
  <div class="database-info bg-white rounded-lg shadow p-6">
    <h2 class="text-xl font-bold mb-4">Database Information</h2>
    
    <div class="space-y-2 mb-4">
      <div class="flex justify-between">
        <span class="text-gray-600">Status:</span>
        <span class="font-semibold text-green-600">Connected</span>
      </div>
      <div class="flex justify-between">
        <span class="text-gray-600">Type:</span>
        <span class="font-semibold">MySQL</span>
      </div>
      <div class="flex justify-between">
        <span class="text-gray-600">Version:</span>
        <span class="font-semibold">8.0</span>
      </div>
      <div class="flex justify-between">
        <span class="text-gray-600">Host:</span>
        <span class="font-semibold">localhost</span>
      </div>
    </div>

    <button 
      @click="toggleCredentials"
      class="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
    >
      {{ showCredentials ? 'Hide Database Info' : 'Check Database' }}
    </button>

    <div v-if="showCredentials" class="mt-4 border-t pt-4">
      <h3 class="text-lg font-semibold mb-3">Database Credentials</h3>
      
      <div class="space-y-2 bg-gray-50 p-4 rounded">
        <div>
          <strong>Host:</strong> localhost:3306
        </div>
        <div>
          <strong>Database:</strong> devop_db
        </div>
        <div>
          <strong>Username:</strong> username
        </div>
        <div>
          <strong>Password:</strong> password
        </div>
        <div>
          <strong>Root Access:</strong> Yes
        </div>
        <div>
          <strong>Connection Status:</strong> concert-mysql
        </div>
      </div>

      <div class="mt-4">
        <h4 class="font-semibold mb-2">Quick Connect Commands</h4>
        <code class="block bg-gray-800 text-white p-2 rounded text-sm">
          docker exec -it concert-mysql mysql -u username -p
        </code>
      </div>

      <div class="mt-4">
        <h4 class="font-semibold mb-2">Database Users</h4>
        <button 
          @click="fetchUsers"
          class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors"
        >
          Refresh Users
        </button>
        
        <div v-if="users.length > 0" class="mt-3">
          <div v-for="user in users" :key="user.user_id" class="border-b py-2">
            <div><strong>Name:</strong> {{ user.name }}</div>
            <div><strong>Email:</strong> {{ user.email }}</div>
            <div><strong>Company:</strong> {{ user.company }}</div>
            <div><strong>Location:</strong> {{ user.city }}, {{ user.country }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import axios from 'axios'

const showCredentials = ref(false)
const users = ref<any[]>([])
const hasFetchedUsers = ref(false)

const toggleCredentials = async () => {
  showCredentials.value = !showCredentials.value
  
  // Auto-fetch users when credentials shown for first time
  if (showCredentials.value && !hasFetchedUsers.value) {
    await fetchUsers()
  }
}

const fetchUsers = async () => {
  try {
    const response = await axios.get('http://localhost:8080/api/users')
    users.value = response.data || []
    hasFetchedUsers.value = true
  } catch (error) {
    console.error('Failed to fetch users:', error)
  }
}
</script>
