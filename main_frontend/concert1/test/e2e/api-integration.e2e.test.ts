import { describe, it, expect, beforeAll } from 'vitest'
import axios from 'axios'

const API_BASE = process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080'
const FRONTEND_BASE = process.env.FRONTEND_BASE || 'http://localhost:3000'

// Helper function to format dates for backend (yyyy-MM-dd'T'HH:mm:ss)
// Backend expects LocalDateTime format without milliseconds or timezone
function formatDateForBackend(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  
  return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`
}

describe('E2E API Integration Tests', () => {
  beforeAll(async () => {
    // Wait a bit for services to be fully ready
    await new Promise(resolve => setTimeout(resolve, 2000))
  })

  describe('Backend API Health', () => {
    it('should have backend actuator health endpoint responding', async () => {
      const response = await axios.get(`${API_BASE}/actuator/health`)
      expect(response.status).toBe(200)
      expect(response.data.status).toBe('UP')
    })

    it('should have auth test endpoint accessible', async () => {
      const response = await axios.get(`${API_BASE}/api/auth/test`)
      expect(response.status).toBe(200)
    })
  })

  describe('Frontend Server', () => {
    it('should have frontend server responding', async () => {
      const response = await axios.get(FRONTEND_BASE)
      expect(response.status).toBe(200)
      expect(response.headers['content-type']).toContain('text/html')
    })
  })

  describe('Authentication Flow', () => {
    const testUser = {
      username: `testuser_${Date.now()}`,
      email: `test_${Date.now()}@example.com`,
      password: 'TestPassword123!'
    }

    it('should register a new user', async () => {
      try {
        const response = await axios.post(`${API_BASE}/api/auth/register`, {
          username: testUser.username,
          email: testUser.email,
          password: testUser.password
        })
        
        console.log('✅ Registration successful:', { status: response.status, hasToken: !!response.data.token })
        expect(response.status).toBe(200)
        expect(response.data).toHaveProperty('token')
        expect(response.data.token).toBeTruthy()
      } catch (error: any) {
        console.error('❌ Registration failed:', {
          status: error.response?.status,
          data: error.response?.data,
          message: error.message
        })
        // User might already exist, which is okay for E2E
        if (error.response?.status !== 400) {
          throw error
        }
      }
    })

    it('should login with valid credentials', async () => {
      // First register if not exists
      try {
        const registerResponse = await axios.post(`${API_BASE}/api/auth/register`, {
          username: testUser.username,
          email: testUser.email,
          password: testUser.password
        })
        console.log('✅ User registered for login test:', { status: registerResponse.status })
      } catch (error: any) {
        console.log('ℹ️ User already exists (expected):', { status: error.response?.status })
        // User might already exist - this is fine
      }

      // Now login - use usernameOrEmail field (backend expects this)
      try {
        const response = await axios.post(`${API_BASE}/api/auth/login`, {
          usernameOrEmail: testUser.username,
          password: testUser.password
        })
        
        console.log('✅ Login successful:', { status: response.status, hasToken: !!response.data.token })
        expect(response.status).toBe(200)
        expect(response.data).toHaveProperty('token')
        expect(response.data.token).toBeTruthy()
      } catch (error: any) {
        console.error('❌ Login failed:', {
          status: error.response?.status,
          data: error.response?.data,
          message: error.message
        })
        throw error
      }
    })

    it('should reject login with invalid credentials', async () => {
      try {
        await axios.post(`${API_BASE}/api/auth/login`, {
          usernameOrEmail: 'nonexistentuser',
          password: 'wrongpassword'
        })
        // Should not reach here
        expect(true).toBe(false)
      } catch (error: any) {
        console.log('✅ Invalid login rejected as expected:', { status: error.response?.status })
        expect(error.response?.status).toBeGreaterThanOrEqual(400)
      }
    })
  })

  describe('Events API', () => {
    let authToken: string

    beforeAll(async () => {
      // Login to get token
      const testUser = {
        username: `eventuser_${Date.now()}`,
        email: `event_${Date.now()}@example.com`,
        password: 'TestPassword123!'
      }

      try {
        const registerResponse = await axios.post(`${API_BASE}/api/auth/register`, {
          username: testUser.username,
          email: testUser.email,
          password: testUser.password
        })
        console.log('✅ Event user registered:', { status: registerResponse.status })
      } catch (error: any) {
        console.log('ℹ️ Event user already exists:', { status: error.response?.status })
        // User might already exist
      }

      const loginResponse = await axios.post(`${API_BASE}/api/auth/login`, {
        usernameOrEmail: testUser.username,
        password: testUser.password
      })
      
      console.log('✅ Event user logged in:', { status: loginResponse.status, hasToken: !!loginResponse.data.token })
      authToken = loginResponse.data.token
    })

    it('should fetch events list (paginated)', async () => {
      const response = await axios.get(`${API_BASE}/api/events`)
      expect(response.status).toBe(200)
      expect(response.data).toHaveProperty('content')
      expect(Array.isArray(response.data.content)).toBe(true)
      expect(response.data).toHaveProperty('totalElements')
      expect(response.data).toHaveProperty('totalPages')
    })

    it('should fetch events with pagination parameters', async () => {
      const response = await axios.get(`${API_BASE}/api/events?page=0&size=5`)
      expect(response.status).toBe(200)
      expect(response.data).toHaveProperty('content')
      expect(Array.isArray(response.data.content)).toBe(true)
      expect(response.data.content.length).toBeLessThanOrEqual(5)
    })

    it('should create a new event with authentication', async () => {
      const newEvent = {
        title: `E2E Test Event ${Date.now()}`,
        description: 'Created by E2E test',
        startDate: formatDateForBackend(new Date(Date.now() + 86400000)),
        endDate: formatDateForBackend(new Date(Date.now() + 172800000)),
        ticketPrice: 99.99,
        personLimit: 100,
        location: 'Test Venue'
      }

      console.log('🎫 Creating event with payload:', { 
        title: newEvent.title,
        startDate: newEvent.startDate,
        endDate: newEvent.endDate
      })

      try {
        const response = await axios.post(
          `${API_BASE}/api/events`,
          newEvent,
          {
            headers: {
              Authorization: `Bearer ${authToken}`,
              'Content-Type': 'application/json'
            }
          }
        )

        console.log('✅ Event created successfully:', { 
          status: response.status, 
          eventId: response.data.id 
        })
        expect(response.status).toBe(200)
        expect(response.data).toHaveProperty('id')
        expect(response.data.title).toBe(newEvent.title)
      } catch (error: any) {
        console.error('❌ Event creation failed:', {
          status: error.response?.status,
          data: error.response?.data,
          message: error.message
        })
        throw error
      }
    })

    it('should reject event creation without authentication', async () => {
      const newEvent = {
        title: `Unauthorized Event ${Date.now()}`,
        description: 'Should fail',
        startDate: formatDateForBackend(new Date(Date.now() + 86400000)),
        endDate: formatDateForBackend(new Date(Date.now() + 172800000)),
        ticketPrice: 99.99,
        personLimit: 100,
        location: 'Test Venue'
      }

      try {
        await axios.post(`${API_BASE}/api/events`, newEvent)
        // Should not reach here
        expect(true).toBe(false)
      } catch (error: any) {
        console.log('✅ Unauthorized event creation rejected as expected:', { 
          status: error.response?.status 
        })
        expect(error.response?.status).toBeGreaterThanOrEqual(401)
      }
    })
  })

  describe('Full User Journey', () => {
    it('should complete register -> login -> create event -> fetch events flow', async () => {
      const timestamp = Date.now()
      const user = {
        username: `journey_${timestamp}`,
        email: `journey_${timestamp}@example.com`,
        password: 'JourneyPass123!'
      }

      // Step 1: Register
      console.log('📝 Step 1: Registering user...')
      const registerResponse = await axios.post(`${API_BASE}/api/auth/register`, user)
      console.log('✅ Registration:', { status: registerResponse.status, hasToken: !!registerResponse.data.token })
      expect(registerResponse.status).toBe(200)
      expect(registerResponse.data.token).toBeTruthy()

      // Step 2: Login - use usernameOrEmail field
      console.log('🔐 Step 2: Logging in...')
      const loginResponse = await axios.post(`${API_BASE}/api/auth/login`, {
        usernameOrEmail: user.username,
        password: user.password
      })
      console.log('✅ Login:', { status: loginResponse.status, hasToken: !!loginResponse.data.token })
      expect(loginResponse.status).toBe(200)
      const token = loginResponse.data.token

      // Step 3: Create Event
      console.log('🎫 Step 3: Creating event...')
      const event = {
        title: `Journey Event ${timestamp}`,
        description: 'Full journey test event',
        startDate: formatDateForBackend(new Date(Date.now() + 86400000)),
        endDate: formatDateForBackend(new Date(Date.now() + 172800000)),
        ticketPrice: 149.99,
        personLimit: 200,
        location: 'Journey Venue'
      }

      console.log('📅 Event dates:', { startDate: event.startDate, endDate: event.endDate })

      const createResponse = await axios.post(
        `${API_BASE}/api/events`,
        event,
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      console.log('✅ Event created:', { status: createResponse.status, eventId: createResponse.data.id })
      expect(createResponse.status).toBe(200)
      const eventId = createResponse.data.id

      // Step 4: Fetch events and verify our event is there
      console.log('📋 Step 4: Fetching events list...')
      const eventsResponse = await axios.get(`${API_BASE}/api/events`)
      console.log('✅ Events fetched:', { 
        status: eventsResponse.status, 
        totalEvents: eventsResponse.data.content?.length 
      })
      expect(eventsResponse.status).toBe(200)
      expect(eventsResponse.data).toHaveProperty('content')
      const foundEvent = eventsResponse.data.content.find((e: any) => e.id === eventId)
      expect(foundEvent).toBeTruthy()
      expect(foundEvent.title).toBe(event.title)

      // Step 5: Fetch single event
      console.log('🔍 Step 5: Fetching single event...')
      const singleEventResponse = await axios.get(`${API_BASE}/api/events/${eventId}`)
      console.log('✅ Single event fetched:', { status: singleEventResponse.status })
      expect(singleEventResponse.status).toBe(200)
      expect(singleEventResponse.data.id).toBe(eventId)
      expect(singleEventResponse.data.title).toBe(event.title)

      console.log('🎉 Full user journey completed successfully!')
    })
  })
})
