<template>
  <div class="user-profile-container">
    <!-- Profile Header -->
    <div class="profile-header">
      <div class="profile-banner">
        <!-- <img src="@/assets/images/profile-banner.svg" alt="Profile Banner" class="banner-image" /> -->
        <div class="banner-placeholder" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); height: 200px;"></div>
      </div>
      
      <div class="profile-info">
        <div class="avatar-section">
          <div class="avatar-wrapper">
            <img 
              :src="userAvatar" 
              :alt="userName" 
              class="profile-avatar"
              @error="onAvatarError"
            />
            <label class="avatar-upload-btn" :title="isEditing ? 'Choose new avatar' : 'Edit profile'">
              <i class="icon-camera"></i>
              <input 
                type="file" 
                hidden 
                @change="handleAvatarChange"
                accept="image/*"
                :disabled="!isEditing"
              />
            </label>
          </div>
          
          <div class="user-details">
            <h1 class="user-name">{{ userName }}</h1>
            <p class="user-email">{{ userEmail }}</p>
            <p class="user-status" :class="userStatusClass">{{ userStatus }}</p>
          </div>
          
          <button 
            @click="toggleEdit" 
            class="btn btn-edit"
            :class="{ active: isEditing }"
          >
            {{ isEditing ? 'Save' : 'Edit Profile' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Profile Stats -->
    <div class="profile-stats">
      <div class="stat-item">
        <span class="stat-value">{{ userStats.bookings }}</span>
        <span class="stat-label">Bookings</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ userStats.events }}</span>
        <span class="stat-label">Attended</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ userStats.followers }}</span>
        <span class="stat-label">Followers</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">{{ userStats.reviews }}</span>
        <span class="stat-label">Reviews</span>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="loading-state">
      <p>Loading profile...</p>
    </div>

    <!-- Error State -->
    <div v-if="loadError" class="error-state">
      <p style="color: #e53e3e; background: #fed7d7; padding: 12px; border-radius: 8px; margin: 20px;">
        {{ loadError }}
      </p>
    </div>

    <!-- Edit Profile Form -->
    <div v-if="isEditing" class="edit-form">
      <div class="form-group">
        <label>Full Name</label>
        <input v-model="editForm.fullName" type="text" placeholder="Enter your full name" />
      </div>
      
      <div class="form-group">
        <label>Email</label>
        <input v-model="editForm.email" type="email" placeholder="Enter your email" disabled />
      </div>
      
      <div class="form-group">
        <label>Phone</label>
        <input v-model="editForm.phone" type="tel" placeholder="Enter your phone number" />
      </div>
      
      <div class="form-group">
        <label>Bio</label>
        <textarea 
          v-model="editForm.bio" 
          placeholder="Tell us about yourself"
          maxlength="500"
          rows="4"
        ></textarea>
        <small>{{ editForm.bio.length }}/500 characters</small>
      </div>
      
      <div class="form-group">
        <label>Location</label>
        <input v-model="editForm.location" type="text" placeholder="City, Country" />
      </div>
      
      <div class="form-group">
        <label>Website</label>
        <input v-model="editForm.website" type="url" placeholder="https://yourwebsite.com" />
      </div>
      
      <div class="form-actions">
        <button @click="toggleEdit" class="btn btn-cancel">Cancel</button>
        <button @click="saveProfile" class="btn btn-primary">Save Changes</button>
      </div>
    </div>

    <!-- Profile Bio (View Mode) -->
    <div v-else class="profile-bio">
      <p v-if="editForm.bio">{{ editForm.bio }}</p>
      <p v-else class="empty-state">No bio added yet. Click edit to add one.</p>
    </div>

    <!-- Additional Info -->
    <div v-if="!isEditing" class="profile-additional-info">
      <div v-if="editForm.location" class="info-item">
        <i class="icon-location"></i>
        <span>{{ editForm.location }}</span>
      </div>
      <div v-if="editForm.website" class="info-item">
        <i class="icon-link"></i>
        <a :href="editForm.website" target="_blank">Website</a>
      </div>
      <div v-if="editForm.phone" class="info-item">
        <i class="icon-phone"></i>
        <span>{{ editForm.phone }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useApi } from '../composables/useApi'
import { useAuth } from '../composables/useAuth'

interface EditFormData {
  fullName: string
  email: string
  phone: string
  bio: string
  location: string
  website: string
}

interface UserStats {
  bookings: number
  events: number
  followers: number
  reviews: number
}

// User data
const userName = ref('John Doe')
const userEmail = ref('john@example.com')
const userStatus = ref('Verified Member')
const userAvatar = ref('https://i.pravatar.cc/150?img=1')
const defaultAvatar = 'https://i.pravatar.cc/150?img=1'
const loadError = ref<string | null>(null)
const isLoading = ref(false)

// Edit state
const isEditing = ref(false)
const editForm = ref<EditFormData>({
  fullName: 'John Doe',
  email: 'john@example.com',
  phone: '+1234567890',
  bio: 'Concert enthusiast and event organizer. Love discovering new artists and attending live performances.',
  location: 'New York, USA',
  website: 'https://johndoe.com'
})

// User stats
const userStats = ref<UserStats>({
  bookings: 24,
  events: 15,
  followers: 342,
  reviews: 18
})

// Load user profile from backend
const loadProfile = async () => {
  try {
    isLoading.value = true
    loadError.value = null
    
    const { apiFetch } = useApi()
    const { getToken } = useAuth()
    const token = getToken()
    
    if (!token) {
      loadError.value = 'Please login to view your profile'
      return
    }
    
    const response = await apiFetch('/api/users/me', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
    
    // Update user data from response
    userName.value = response.name || 'User'
    userEmail.value = response.email || ''
    editForm.value.fullName = response.name || ''
    editForm.value.email = response.email || ''
    editForm.value.phone = response.phone || ''
    editForm.value.location = response.address || ''
    editForm.value.website = response.website || ''
    
  } catch (error: any) {
    console.error('Failed to load profile:', error)
    loadError.value = error?.data?.message || error?.message || 'Not Found'
  } finally {
    isLoading.value = false
  }
}

// Load profile on component mount
onMounted(() => {
  loadProfile()
})

// Computed
const userStatusClass = computed(() => {
  if (userStatus.value === 'Verified Member') return 'verified'
  if (userStatus.value === 'Premium Member') return 'premium'
  return 'standard'
})

// Methods
const toggleEdit = () => {
  if (isEditing.value) {
    // Reset form if cancelled
    editForm.value.fullName = userName.value
  }
  isEditing.value = !isEditing.value
}

const saveProfile = async () => {
  try {
    const { apiFetch } = useApi()
    const { getToken } = useAuth()
    const token = getToken()
    
    if (!token) {
      console.error('No authentication token found')
      alert('Please login to update your profile')
      return
    }
    
    // Parse name into firstName and lastName
    const nameParts = editForm.value.fullName.trim().split(' ')
    const firstName = nameParts[0] || ''
    const lastName = nameParts.slice(1).join(' ') || ''
    
    // Call API to save profile
    const response = await apiFetch('/api/users/me', {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: {
        firstName: firstName,
        lastName: lastName,
        phone: editForm.value.phone,
        address: editForm.value.location,
        city: '',
        country: '',
        pincode: '',
        website: editForm.value.website
      }
    })
    
    // Update profile data
    userName.value = editForm.value.fullName
    
    isEditing.value = false
    alert('Profile updated successfully!')
  } catch (error: any) {
    console.error('Failed to save profile:', error)
    const errorMsg = error?.data?.message || error?.message || 'Failed to update profile'
    alert('Error: ' + errorMsg)
  }
}

const handleAvatarChange = async (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  
  if (file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      userAvatar.value = e.target?.result as string
      // Upload to server
      // uploadAvatar(file)
    }
    reader.readAsDataURL(file)
  }
}

const onAvatarError = () => {
  userAvatar.value = defaultAvatar
}
</script>

<style scoped lang="scss">
.user-profile-container {
  max-width: 900px;
  margin: 0 auto;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.profile-header {
  position: relative;
}

.profile-banner {
  height: 200px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  overflow: hidden;
  position: relative;

  .banner-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}

.profile-info {
  padding: 0 40px 40px;
  position: relative;
  margin-top: -80px;
}

.avatar-section {
  display: flex;
  align-items: flex-start;
  gap: 30px;
}

.avatar-wrapper {
  position: relative;
  flex-shrink: 0;
}

.profile-avatar {
  width: 150px;
  height: 150px;
  border-radius: 50%;
  border: 5px solid white;
  object-fit: cover;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.avatar-upload-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 40px;
  height: 40px;
  background: #667eea;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);

  &:hover {
    background: #764ba2;
    transform: scale(1.1);
  }

  i {
    font-size: 18px;
  }
}

.user-details {
  flex: 1;
  padding-top: 20px;
}

.user-name {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 8px;
  color: #1a1a1a;
}

.user-email {
  font-size: 16px;
  color: #666;
  margin: 0 0 12px;
}

.user-status {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
  margin: 0;

  &.verified {
    background: #e3f2fd;
    color: #1976d2;
  }

  &.premium {
    background: #fff3e0;
    color: #f57c00;
  }

  &.standard {
    background: #f5f5f5;
    color: #666;
  }
}

.btn-edit {
  margin-top: 12px;
}

.profile-stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  padding: 30px 40px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;

  @media (max-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }
}

.stat-item {
  text-align: center;

  .stat-value {
    display: block;
    font-size: 28px;
    font-weight: 700;
    color: #667eea;
    margin-bottom: 5px;
  }

  .stat-label {
    display: block;
    font-size: 13px;
    color: #999;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
}

.profile-bio {
  padding: 30px 40px;
  border-bottom: 1px solid #f0f0f0;

  p {
    margin: 0;
    line-height: 1.6;
    color: #333;
    font-size: 15px;

    &.empty-state {
      color: #999;
      font-style: italic;
    }
  }
}

.profile-additional-info {
  display: flex;
  flex-direction: column;
  gap: 15px;
  padding: 30px 40px;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  color: #333;

  i {
    font-size: 18px;
    color: #667eea;
    width: 24px;
    text-align: center;
  }

  a {
    color: #667eea;
    text-decoration: none;

    &:hover {
      text-decoration: underline;
    }
  }
}

.edit-form {
  padding: 30px 40px;

  .form-group {
    margin-bottom: 24px;

    label {
      display: block;
      font-weight: 600;
      margin-bottom: 8px;
      color: #333;
      font-size: 14px;
    }

    input,
    textarea {
      width: 100%;
      padding: 12px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 14px;
      font-family: inherit;
      transition: border-color 0.2s ease;

      &:focus {
        outline: none;
        border-color: #667eea;
        box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
      }

      &:disabled {
        background: #f5f5f5;
        cursor: not-allowed;
        color: #999;
      }
    }

    textarea {
      resize: vertical;
    }

    small {
      display: block;
      margin-top: 6px;
      color: #999;
      font-size: 12px;
    }
  }
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
  margin-top: 20px;
}

.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;

  &.btn-edit {
    background: #667eea;
    color: white;

    &:hover {
      background: #764ba2;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
    }

    &.active {
      background: #764ba2;
    }
  }

  &.btn-primary {
    background: #667eea;
    color: white;

    &:hover {
      background: #764ba2;
    }
  }

  &.btn-cancel {
    background: #f5f5f5;
    color: #333;

    &:hover {
      background: #e8e8e8;
    }
  }
}
</style>
