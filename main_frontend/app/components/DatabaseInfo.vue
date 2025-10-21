<template>
  <div class="p-4 max-w-md mx-auto">
    <div class="bg-white rounded-lg shadow-md p-6">
      <h2 class="text-xl font-bold text-gray-800 mb-4">Database Information</h2>
      
      <button 
        @click="toggleCredentials"
        :class="[
          'w-full py-2 px-4 rounded transition-colors mb-4',
          showCredentials ? 'bg-red-500 hover:bg-red-600 text-white' : 'bg-blue-500 hover:bg-blue-600 text-white'
        ]"
      >
        {{ showCredentials ? 'Hide Database Info' : 'Check Database' }}
      </button>

      <div v-if="showCredentials" class="space-y-4">
        <div class="bg-gray-100 p-4 rounded border-l-4 border-blue-500">
          <h3 class="font-semibold text-gray-700 mb-2">Database Credentials</h3>
          
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Host:</span>
              <code class="bg-gray-200 px-2 py-1 rounded text-sm">localhost:3306</code>
            </div>
            
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Database:</span>
              <code class="bg-gray-200 px-2 py-1 rounded text-sm">devop_db</code>
            </div>
            
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Username:</span>
              <code class="bg-gray-200 px-2 py-1 rounded text-sm">username</code>
            </div>
            
            <div class="flex justify-between items-center">
              <span class="text-gray-600">Password:</span>
              <code class="bg-gray-200 px-2 py-1 rounded text-sm">password</code>
            </div>
          </div>
        </div>

        <div class="bg-yellow-100 p-4 rounded border-l-4 border-yellow-500">
          <h3 class="font-semibold text-yellow-700 mb-2">Root Access</h3>
          
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <span class="text-yellow-600">Root Password:</span>
              <code class="bg-yellow-200 px-2 py-1 rounded text-sm">password</code>
            </div>
          </div>
        </div>

        <div class="bg-green-100 p-4 rounded border-l-4 border-green-500">
          <h3 class="font-semibold text-green-700 mb-2">Connection Status</h3>
          
          <div class="flex items-center space-x-2">
            <div class="w-2 h-2 bg-green-500 rounded-full"></div>
            <span class="text-green-600">Database is running in Docker container</span>
          </div>
          
          <div class="mt-2 text-sm text-green-600">
            Container: <code class="bg-green-200 px-1 rounded">concert-mysql</code>
          </div>
        </div>

        <div class="bg-blue-100 p-4 rounded border-l-4 border-blue-500">
          <h3 class="font-semibold text-blue-700 mb-2">Quick Connect Commands</h3>
          
          <div class="space-y-2 text-sm">
            <div>
              <span class="text-blue-600">Docker exec:</span>
              <code class="block bg-blue-200 p-2 rounded mt-1 text-xs overflow-x-auto">
                docker exec -it concert-mysql mysql -u username -ppassword devop_db
              </code>
            </div>
            
            <div>
              <span class="text-blue-600">MySQL client:</span>
              <code class="block bg-blue-200 p-2 rounded mt-1 text-xs overflow-x-auto">
                mysql -h localhost -P 3306 -u username -ppassword devop_db
              </code>
            </div>
          </div>
        </div>

        <div class="bg-purple-100 p-4 rounded border-l-4 border-purple-500">
          <h3 class="font-semibold text-purple-700 mb-2">Database Users</h3>
          
          <div v-if="loading" class="text-purple-600">
            Loading users...
          </div>
          
          <div v-else-if="users.length > 0" class="space-y-2 max-h-64 overflow-y-auto">
            <div 
              v-for="user in users" 
              :key="user.user_id"
              class="bg-purple-50 p-2 rounded text-sm"
            >
              <div class="flex justify-between items-center">
                <span class="font-medium text-purple-800">{{ user.name }}</span>
                <span class="text-purple-600 text-xs">ID: {{ user.user_id }}</span>
              </div>
              <div class="text-purple-600 text-xs">{{ user.email }}</div>
              <div class="text-purple-600 text-xs">{{ user.company }} - {{ user.city }}, {{ user.country }}</div>
            </div>
          </div>
          
          <div v-else class="text-purple-600">
            No users found in database
          </div>
          
          <button 
            @click="fetchUsers"
            class="mt-2 px-3 py-1 bg-purple-500 text-white rounded text-sm hover:bg-purple-600"
          >
            Refresh Users
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'

const showCredentials = ref(false)
const users = ref([])
const loading = ref(false)

const toggleCredentials = () => {
  showCredentials.value = !showCredentials.value
  if (showCredentials.value && users.value.length === 0) {
    fetchUsers()
  }
}

const fetchUsers = async () => {
  loading.value = true
  try {
    const response = await axios.get('http://localhost:8080/api/users')
    users.value = response.data
  } catch (error) {
    console.error('Error fetching users:', error)
    users.value = []
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
/* Additional styling if needed */
code {
  font-family: 'Courier New', monospace;
}
</style>
