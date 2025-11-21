/**
 * E2E Test Setup
 * 
 * This file is executed before E2E tests run.
 * Use it to configure the test environment.
 */

import { beforeAll, afterAll } from 'vitest'

// Set test environment variables
beforeAll(() => {
  // Configure API endpoints
  process.env.NUXT_PUBLIC_API_BASE = process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080'
  
  // Set test mode
  process.env.NODE_ENV = 'test'
  
  console.log('🚀 E2E Test Environment Setup Complete')
  console.log(`📡 API Base: ${process.env.NUXT_PUBLIC_API_BASE}`)
})

afterAll(() => {
  console.log('✅ E2E Tests Complete')
})

// Global test utilities
export const testConfig = {
  apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080',
  timeout: 30000,
  retries: 2
}

export const testCredentials = {
  validUser: {
    username: 'testuser',
    email: 'test@example.com',
    password: 'testpassword123'
  },
  invalidUser: {
    username: 'invaliduser',
    password: 'wrongpassword'
  }
}

// Helper function to wait for API readiness
export async function waitForApiReady(maxRetries = 10): Promise<boolean> {
  const apiUrl = testConfig.apiBaseUrl
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(`${apiUrl}/api/auth/test`)
      if (response.ok) {
        console.log('✅ Backend API is ready')
        return true
      }
    } catch (error) {
      console.log(`⏳ Waiting for backend API... (${i + 1}/${maxRetries})`)
      await new Promise(resolve => setTimeout(resolve, 2000))
    }
  }
  
  console.error('❌ Backend API is not responding')
  return false
}

// Helper function to create test data
export const testData = {
  event: {
    title: 'E2E Test Concert',
    description: 'Test event created by E2E tests',
    startDate: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
    endDate: new Date(Date.now() + 172800000).toISOString(), // Day after tomorrow
    price: 99.99,
    capacity: 100,
    location: 'Test Venue'
  }
}
