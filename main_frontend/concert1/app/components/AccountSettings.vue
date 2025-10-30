<template>
  <div class="account-settings-container">
    <div class="settings-header">
      <h1>Account Settings</h1>
      <p>Manage your account security, preferences, and notifications</p>
    </div>

    <div class="settings-layout">
      <!-- Settings Navigation -->
      <nav class="settings-nav">
        <button 
          v-for="tab in settingsTabs"
          :key="tab.id"
          :class="['nav-item', { active: activeTab === tab.id }]"
          @click="activeTab = tab.id"
        >
          <i :class="tab.icon"></i>
          <span>{{ tab.label }}</span>
        </button>
      </nav>

      <!-- Settings Content -->
      <div class="settings-content">
        <!-- Security Settings -->
        <section v-if="activeTab === 'security'" class="settings-section">
          <h2>Security Settings</h2>

          <!-- Password -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Password</h3>
              <p>Change your password to keep your account secure</p>
            </div>
            <button @click="showPasswordModal = true" class="btn btn-secondary">
              Change Password
            </button>
          </div>

          <!-- Two-Factor Authentication -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Two-Factor Authentication</h3>
              <p>Add an extra layer of security to your account</p>
            </div>
            <div class="setting-body">
              <label class="toggle-switch">
                <input v-model="settings.twoFactorEnabled" type="checkbox" />
                <span class="toggle-slider"></span>
                <span class="toggle-label">
                  {{ settings.twoFactorEnabled ? 'Enabled' : 'Disabled' }}
                </span>
              </label>
            </div>
          </div>

          <!-- Login Sessions -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Active Sessions</h3>
              <p>Manage your active login sessions</p>
            </div>
            <div class="sessions-list">
              <div v-for="session in activeSessions" :key="session.id" class="session-item">
                <div class="session-info">
                  <div class="session-device">
                    <i :class="session.deviceIcon"></i>
                    <span>{{ session.device }}</span>
                  </div>
                  <div class="session-details">
                    <small>{{ session.location }} • {{ session.ip }}</small>
                    <small v-if="session.isCurrent" class="current-badge">Current</small>
                  </div>
                </div>
                <button 
                  v-if="!session.isCurrent"
                  @click="logoutSession(session.id)"
                  class="btn btn-small btn-danger"
                >
                  Logout
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Privacy Settings -->
        <section v-if="activeTab === 'privacy'" class="settings-section">
          <h2>Privacy Settings</h2>

          <!-- Profile Visibility -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Profile Visibility</h3>
              <p>Control who can see your profile</p>
            </div>
            <div class="setting-body">
              <div class="radio-group">
                <label v-for="option in privacyOptions" :key="option.value" class="radio-option">
                  <input 
                    v-model="settings.profileVisibility" 
                    type="radio" 
                    :value="option.value"
                  />
                  <span class="radio-label">{{ option.label }}</span>
                  <span class="radio-desc">{{ option.description }}</span>
                </label>
              </div>
            </div>
          </div>

          <!-- Show Email Publicly -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Email Visibility</h3>
              <p>Allow others to see your email address</p>
            </div>
            <label class="toggle-switch">
              <input v-model="settings.emailPublic" type="checkbox" />
              <span class="toggle-slider"></span>
              <span class="toggle-label">{{ settings.emailPublic ? 'Public' : 'Private' }}</span>
            </label>
          </div>

          <!-- Block Users -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Blocked Users</h3>
              <p>Manage users you've blocked</p>
            </div>
            <div v-if="blockedUsers.length > 0" class="blocked-users-list">
              <div v-for="user in blockedUsers" :key="user.id" class="blocked-user">
                <img :src="user.avatar" :alt="user.name" class="user-avatar" />
                <div class="user-info">
                  <p class="user-name">{{ user.name }}</p>
                  <small>Blocked on {{ formatDate(user.blockedAt) }}</small>
                </div>
                <button @click="unblockUser(user.id)" class="btn btn-small">Unblock</button>
              </div>
            </div>
            <p v-else class="empty-state">No blocked users</p>
          </div>
        </section>

        <!-- Notification Settings -->
        <section v-if="activeTab === 'notifications'" class="settings-section">
          <h2>Notification Preferences</h2>

          <div class="notification-types">
            <div v-for="notif in notificationSettings" :key="notif.id" class="setting-card">
              <div class="setting-header">
                <h3>{{ notif.title }}</h3>
                <p>{{ notif.description }}</p>
              </div>
              <div class="setting-body">
                <label v-for="channel in notif.channels" :key="channel" class="checkbox-option">
                  <input 
                    v-model="settings.notifications[notif.id][channel]" 
                    type="checkbox"
                  />
                  <span>{{ channel | capitalize }}</span>
                </label>
              </div>
            </div>
          </div>
        </section>

        <!-- Billing Settings -->
        <section v-if="activeTab === 'billing'" class="settings-section">
          <h2>Billing & Payments</h2>

          <!-- Payment Methods -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Payment Methods</h3>
              <button @click="showPaymentModal = true" class="btn btn-small btn-primary">
                Add Card
              </button>
            </div>
            <div v-if="paymentMethods.length > 0" class="payment-methods-list">
              <div v-for="card in paymentMethods" :key="card.id" class="payment-method">
                <div class="card-info">
                  <i :class="getCardIcon(card.brand)"></i>
                  <div class="card-details">
                    <p>{{ card.brand }} •••• {{ card.lastFour }}</p>
                    <small>Expires {{ card.expiry }}</small>
                  </div>
                </div>
                <button @click="removePaymentMethod(card.id)" class="btn btn-small btn-danger">
                  Remove
                </button>
              </div>
            </div>
          </div>

          <!-- Billing Address -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Billing Address</h3>
            </div>
            <p v-if="billingAddress" class="billing-info">
              {{ billingAddress.street }}<br>
              {{ billingAddress.city }}, {{ billingAddress.state }} {{ billingAddress.zip }}<br>
              {{ billingAddress.country }}
            </p>
            <button @click="showBillingModal = true" class="btn btn-secondary">
              {{ billingAddress ? 'Update' : 'Add' }} Billing Address
            </button>
          </div>

          <!-- Invoices -->
          <div class="setting-card">
            <div class="setting-header">
              <h3>Invoices</h3>
            </div>
            <div v-if="invoices.length > 0" class="invoices-list">
              <div v-for="invoice in invoices" :key="invoice.id" class="invoice-item">
                <div class="invoice-info">
                  <p class="invoice-id">Invoice #{{ invoice.number }}</p>
                  <small>{{ formatDate(invoice.date) }} • {{ invoice.amount }}</small>
                </div>
                <button @click="downloadInvoice(invoice.id)" class="btn btn-small">
                  Download
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Connected Apps -->
        <section v-if="activeTab === 'apps'" class="settings-section">
          <h2>Connected Applications</h2>

          <div v-for="app in connectedApps" :key="app.id" class="setting-card">
            <div class="app-info">
              <img :src="app.icon" :alt="app.name" class="app-icon" />
              <div class="app-details">
                <h3>{{ app.name }}</h3>
                <p>Connected on {{ formatDate(app.connectedAt) }}</p>
                <p class="permissions">{{ app.permissions.join(', ') }}</p>
              </div>
              <button @click="disconnectApp(app.id)" class="btn btn-danger">
                Disconnect
              </button>
            </div>
          </div>
        </section>

        <!-- Account Danger Zone -->
        <section v-if="activeTab === 'danger'" class="settings-section danger-zone">
          <h2>Danger Zone</h2>

          <div class="setting-card danger">
            <div class="setting-header">
              <h3>Delete Account</h3>
              <p>Permanently delete your account and all associated data</p>
            </div>
            <button @click="showDeleteModal = true" class="btn btn-danger">
              Delete Account
            </button>
          </div>
        </section>
      </div>
    </div>

    <!-- Modals -->
    <PasswordChangeModal v-if="showPasswordModal" @close="showPasswordModal = false" />
    <PaymentMethodModal v-if="showPaymentModal" @close="showPaymentModal = false" />
    <BillingAddressModal v-if="showBillingModal" @close="showBillingModal = false" />
    <DeleteAccountModal v-if="showDeleteModal" @close="showDeleteModal = false" />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

// Modal states
const showPasswordModal = ref(false)
const showPaymentModal = ref(false)
const showBillingModal = ref(false)
const showDeleteModal = ref(false)

// Active tab
const activeTab = ref('security')

// Settings tabs
const settingsTabs = [
  { id: 'security', label: 'Security', icon: 'icon-lock' },
  { id: 'privacy', label: 'Privacy', icon: 'icon-eye' },
  { id: 'notifications', label: 'Notifications', icon: 'icon-bell' },
  { id: 'billing', label: 'Billing', icon: 'icon-card' },
  { id: 'apps', label: 'Apps', icon: 'icon-app' },
  { id: 'danger', label: 'Danger Zone', icon: 'icon-warning' }
]

// Settings data
const settings = ref({
  twoFactorEnabled: false,
  profileVisibility: 'public',
  emailPublic: false,
  notifications: {
    bookings: { email: true, sms: false, push: true },
    events: { email: true, sms: false, push: true },
    messages: { email: true, sms: true, push: true },
    updates: { email: false, sms: false, push: true }
  }
})

const privacyOptions = [
  { value: 'public', label: 'Public', description: 'Everyone can see your profile' },
  { value: 'friends', label: 'Friends Only', description: 'Only people you follow can see your profile' },
  { value: 'private', label: 'Private', description: 'No one can see your profile' }
]

const activeSessions = [
  {
    id: '1',
    device: 'Safari on macOS',
    location: 'New York, USA',
    ip: '192.168.1.1',
    isCurrent: true,
    deviceIcon: 'icon-apple'
  },
  {
    id: '2',
    device: 'Chrome on Windows',
    location: 'Los Angeles, USA',
    ip: '192.168.1.2',
    isCurrent: false,
    deviceIcon: 'icon-windows'
  }
]

const blockedUsers = ref([
  {
    id: '1',
    name: 'John Smith',
    avatar: 'https://i.pravatar.cc/150?img=2',
    blockedAt: new Date('2024-10-20')
  }
])

const notificationSettings = [
  {
    id: 'bookings',
    title: 'Booking Notifications',
    description: 'Receive updates about your bookings',
    channels: ['email', 'sms', 'push']
  },
  {
    id: 'events',
    title: 'Event Updates',
    description: 'Get notified about your favorite events',
    channels: ['email', 'sms', 'push']
  },
  {
    id: 'messages',
    title: 'Messages',
    description: 'Messages from other users',
    channels: ['email', 'sms', 'push']
  },
  {
    id: 'updates',
    title: 'Platform Updates',
    description: 'Important updates about the platform',
    channels: ['email', 'sms', 'push']
  }
]

const paymentMethods = ref([
  { id: '1', brand: 'Visa', lastFour: '4242', expiry: '12/25' },
  { id: '2', brand: 'Mastercard', lastFour: '5555', expiry: '08/26' }
])

const billingAddress = ref({
  street: '123 Main St',
  city: 'New York',
  state: 'NY',
  zip: '10001',
  country: 'USA'
})

const invoices = ref([
  { id: '1', number: '001', date: new Date('2024-10-01'), amount: '$99.99' },
  { id: '2', number: '002', date: new Date('2024-09-01'), amount: '$99.99' }
])

const connectedApps = ref([
  {
    id: '1',
    name: 'Spotify',
    icon: 'https://via.placeholder.com/40',
    connectedAt: new Date('2024-09-15'),
    permissions: ['Read favorites', 'Create playlists']
  },
  {
    id: '2',
    name: 'Google Calendar',
    icon: 'https://via.placeholder.com/40',
    connectedAt: new Date('2024-08-20'),
    permissions: ['Add events', 'Read calendar']
  }
])

// Methods
const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US').format(date)
}

const logoutSession = (sessionId: string) => {
  console.log('Logout session:', sessionId)
}

const unblockUser = (userId: string) => {
  blockedUsers.value = blockedUsers.value.filter(u => u.id !== userId)
}

const removePaymentMethod = (cardId: string) => {
  paymentMethods.value = paymentMethods.value.filter(c => c.id !== cardId)
}

const downloadInvoice = (invoiceId: string) => {
  console.log('Download invoice:', invoiceId)
}

const disconnectApp = (appId: string) => {
  connectedApps.value = connectedApps.value.filter(a => a.id !== appId)
}

const getCardIcon = (brand: string) => {
  const icons: Record<string, string> = {
    'Visa': 'icon-visa',
    'Mastercard': 'icon-mastercard',
    'Amex': 'icon-amex'
  }
  return icons[brand] || 'icon-card'
}
</script>

<style scoped lang="scss">
.account-settings-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

.settings-header {
  margin-bottom: 40px;

  h1 {
    font-size: 32px;
    font-weight: 700;
    margin: 0 0 8px;
    color: #1a1a1a;
  }

  p {
    font-size: 16px;
    color: #666;
    margin: 0;
  }
}

.settings-layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  gap: 40px;

  @media (max-width: 768px) {
    grid-template-columns: 1fr;
    gap: 20px;
  }
}

.settings-nav {
  display: flex;
  flex-direction: column;
  gap: 8px;
  position: sticky;
  top: 20px;
  height: fit-content;

  @media (max-width: 768px) {
    flex-direction: row;
    overflow-x: auto;
    padding-bottom: 8px;
    top: auto;
    position: static;
  }

  .nav-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    border: none;
    border-radius: 8px;
    background: transparent;
    color: #666;
    font-size: 15px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
    white-space: nowrap;

    &:hover {
      background: #f5f5f5;
      color: #333;
    }

    &.active {
      background: #667eea;
      color: white;
    }

    i {
      font-size: 18px;
    }
  }
}

.settings-content {
  .settings-section {
    margin-bottom: 40px;

    h2 {
      font-size: 24px;
      font-weight: 700;
      margin: 0 0 24px;
      color: #1a1a1a;
    }
  }
}

.setting-card {
  background: white;
  border: 1px solid #e8e8e8;
  border-radius: 8px;
  padding: 24px;
  margin-bottom: 16px;
  transition: all 0.2s ease;

  &:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  }

  &.danger {
    border-color: #ff6b6b;
    background: #fff5f5;
  }
}

.setting-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;

  h3 {
    font-size: 16px;
    font-weight: 600;
    margin: 0 0 4px;
    color: #1a1a1a;
  }

  p {
    font-size: 14px;
    color: #666;
    margin: 0;
  }

  @media (max-width: 768px) {
    flex-direction: column;
    gap: 12px;
  }
}

.setting-body {
  margin-top: 16px;
}

// Toggle Switch
.toggle-switch {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;

  input {
    width: 0;
    height: 0;
    opacity: 0;
  }

  .toggle-slider {
    width: 48px;
    height: 28px;
    background: #ddd;
    border-radius: 14px;
    position: relative;
    transition: background 0.2s ease;

    &::after {
      content: '';
      position: absolute;
      width: 24px;
      height: 24px;
      background: white;
      border-radius: 50%;
      top: 2px;
      left: 2px;
      transition: left 0.2s ease;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
  }

  input:checked + .toggle-slider {
    background: #667eea;

    &::after {
      left: 22px;
    }
  }

  .toggle-label {
    font-size: 14px;
    color: #666;
  }
}

// Radio Group
.radio-group {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.radio-option {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  cursor: pointer;

  input {
    width: 20px;
    height: 20px;
    margin-top: 2px;
    cursor: pointer;
  }

  .radio-label {
    display: block;
    font-weight: 500;
    color: #333;
    font-size: 15px;
  }

  .radio-desc {
    display: block;
    font-size: 13px;
    color: #999;
  }
}

// Checkbox Option
.checkbox-option {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 14px;
  color: #333;
  margin-bottom: 8px;

  input {
    cursor: pointer;
  }
}

// Sessions List
.sessions-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.session-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #f9f9f9;
  border-radius: 6px;

  .session-info {
    flex: 1;
  }

  .session-device {
    display: flex;
    align-items: center;
    gap: 8px;
    font-weight: 500;
    color: #333;
    margin-bottom: 4px;

    i {
      font-size: 18px;
      color: #667eea;
    }
  }

  .session-details {
    display: flex;
    gap: 12px;
    align-items: center;
    font-size: 12px;
    color: #999;

    .current-badge {
      background: #e3f2fd;
      color: #1976d2;
      padding: 2px 8px;
      border-radius: 12px;
    }
  }
}

// Blocked Users
.blocked-users-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.blocked-user {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f9f9f9;
  border-radius: 6px;

  .user-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    object-fit: cover;
  }

  .user-info {
    flex: 1;

    .user-name {
      font-weight: 500;
      color: #333;
      margin: 0 0 4px;
      font-size: 14px;
    }

    small {
      color: #999;
      display: block;
    }
  }
}

// Payment Methods
.payment-methods-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 16px;
}

.payment-method {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #f9f9f9;
  border-radius: 6px;

  .card-info {
    display: flex;
    align-items: center;
    gap: 12px;
    flex: 1;

    i {
      font-size: 24px;
      color: #667eea;
    }

    .card-details {
      p {
        font-weight: 500;
        color: #333;
        margin: 0 0 2px;
        font-size: 14px;
      }

      small {
        color: #999;
      }
    }
  }
}

// Invoices
.invoices-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 16px;
}

.invoice-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #f9f9f9;
  border-radius: 6px;

  .invoice-info {
    flex: 1;

    .invoice-id {
      font-weight: 500;
      color: #333;
      margin: 0 0 4px;
      font-size: 14px;
    }

    small {
      color: #999;
    }
  }
}

// Connected Apps
.app-info {
  display: flex;
  align-items: flex-start;
  gap: 16px;

  .app-icon {
    width: 40px;
    height: 40px;
    border-radius: 6px;
    object-fit: cover;
  }

  .app-details {
    flex: 1;

    h3 {
      font-size: 16px;
      font-weight: 600;
      margin: 0 0 4px;
      color: #333;
    }

    p {
      font-size: 14px;
      color: #999;
      margin: 0 0 4px;

      &.permissions {
        color: #666;
      }
    }
  }
}

// Danger Zone
.danger-zone {
  .setting-card.danger {
    background: #fff5f5;
  }
}

// Buttons
.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;

  &.btn-primary {
    background: #667eea;
    color: white;

    &:hover {
      background: #764ba2;
    }
  }

  &.btn-secondary {
    background: #f5f5f5;
    color: #333;

    &:hover {
      background: #e8e8e8;
    }
  }

  &.btn-danger {
    background: #ff6b6b;
    color: white;

    &:hover {
      background: #ff5252;
    }
  }

  &.btn-small {
    padding: 6px 12px;
    font-size: 12px;
  }
}

.empty-state {
  color: #999;
  font-style: italic;
  margin: 0;
}

.billing-info {
  margin: 0 0 16px;
  color: #333;
  font-size: 14px;
  line-height: 1.6;
}
</style>
