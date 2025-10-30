<template>
  <div class="user-dashboard">
    <!-- Navigation Tabs -->
    <div class="dashboard-nav">
      <NuxtLink to="/account/profile" class="nav-link" :class="{ active: $route.path === '/account/profile' }">
        <i class="icon-user"></i> Profile
      </NuxtLink>
      <NuxtLink to="/account/bookings" class="nav-link" :class="{ active: $route.path === '/account/bookings' }">
        <i class="icon-calendar"></i> My Bookings
      </NuxtLink>
      <NuxtLink to="/account/favorites" class="nav-link" :class="{ active: $route.path === '/account/favorites' }">
        <i class="icon-heart"></i> Favorites
      </NuxtLink>
      <NuxtLink to="/account/settings" class="nav-link" :class="{ active: $route.path === '/account/settings' }">
        <i class="icon-gear"></i> Settings
      </NuxtLink>
    </div>

    <!-- Page Content -->
    <div class="dashboard-content">
      <NuxtPage />
    </div>
  </div>
</template>

<script setup lang="ts">
// Dashboard layout component
</script>

<style scoped lang="scss">
.user-dashboard {
  min-height: calc(100vh - 80px);
  background: #f8f9fa;
}

.dashboard-nav {
  display: flex;
  gap: 0;
  background: white;
  border-bottom: 1px solid #e8e8e8;
  padding: 0 40px;
  position: sticky;
  top: 80px;
  z-index: 10;

  @media (max-width: 768px) {
    padding: 0 20px;
    overflow-x: auto;
    scroll-behavior: smooth;

    &::-webkit-scrollbar {
      height: 3px;
    }

    &::-webkit-scrollbar-track {
      background: transparent;
    }

    &::-webkit-scrollbar-thumb {
      background: #ddd;
      border-radius: 3px;
    }
  }

  .nav-link {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 16px 0;
    border: none;
    background: none;
    color: #666;
    font-size: 15px;
    font-weight: 500;
    text-decoration: none;
    cursor: pointer;
    transition: all 0.2s ease;
    border-bottom: 3px solid transparent;
    margin-bottom: -1px;
    white-space: nowrap;

    &:hover {
      color: #667eea;
    }

    &.active {
      color: #667eea;
      border-bottom-color: #667eea;
    }

    i {
      font-size: 18px;
    }
  }
}

.dashboard-content {
  padding: 40px;

  @media (max-width: 768px) {
    padding: 20px;
  }
}
</style>
