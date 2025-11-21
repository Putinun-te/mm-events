import { describe, it, expect, beforeAll } from 'vitest'
import axios from 'axios'

const API_BASE = process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080'
const FRONTEND_BASE = process.env.FRONTEND_BASE || 'http://localhost:3000'

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
          password: testUser.password,
          name: 'Test User'
        })
        
        expect(response.status).toBe(200)
        expect(response.data).toHaveProperty('token')
        expect(response.data.token).toBeTruthy()
      } catch (error: any) {
        // User might already exist, which is okay for E2E
        if (error.response?.status !== 400) {
          throw error
        }
      }
    })

    it('should login with valid credentials', async () => {
      // First register if not exists
      try {
        await axios.post(`${API_BASE}/api/auth/register`, {
          username: testUser.username,
          email: testUser.email,
          password: testUser.password,
          name: 'Test User'
        })
      } catch (error) {
        // User might already exist
      }

      // Now login
      const response = await axios.post(`${API_BASE}/api/auth/login`, {
        username: testUser.username,
        password: testUser.password
      })
      
      expect(response.status).toBe(200)
      expect(response.data).toHaveProperty('token')
      expect(response.data.token).toBeTruthy()
    })

    it('should reject login with invalid credentials', async () => {
      try {
        await axios.post(`${API_BASE}/api/auth/login`, {
          username: 'nonexistentuser',
          password: 'wrongpassword'
        })
        // Should not reach here
        expect(true).toBe(false)
      } catch (error: any) {
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
        await axios.post(`${API_BASE}/api/auth/register`, {
          username: testUser.username,
          email: testUser.email,
          password: testUser.password,
          name: 'Event User'
        })
      } catch (error) {
        // User might already exist
      }

      const loginResponse = await axios.post(`${API_BASE}/api/auth/login`, {
        username: testUser.username,
        password: testUser.password
      })
      
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
        startDate: new Date(Date.now() + 86400000).toISOString(),
        endDate: new Date(Date.now() + 172800000).toISOString(),
        ticketPrice: 99.99,
        personLimit: 100,
        location: 'Test Venue'
      }

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

      expect(response.status).toBe(200)
      expect(response.data).toHaveProperty('id')
      expect(response.data.title).toBe(newEvent.title)
    })

    it('should reject event creation without authentication', async () => {
      const newEvent = {
        title: `Unauthorized Event ${Date.now()}`,
        description: 'Should fail',
        startDate: new Date(Date.now() + 86400000).toISOString(),
        endDate: new Date(Date.now() + 172800000).toISOString(),
        ticketPrice: 99.99,
        personLimit: 100,
        location: 'Test Venue'
      }

      try {
        await axios.post(`${API_BASE}/api/events`, newEvent)
        // Should not reach here
        expect(true).toBe(false)
      } catch (error: any) {
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
        password: 'JourneyPass123!',
        name: 'Journey User'
      }

      // Step 1: Register
      const registerResponse = await axios.post(`${API_BASE}/api/auth/register`, user)
      expect(registerResponse.status).toBe(200)
      expect(registerResponse.data.token).toBeTruthy()

      // Step 2: Login
      const loginResponse = await axios.post(`${API_BASE}/api/auth/login`, {
        username: user.username,
        password: user.password
      })
      expect(loginResponse.status).toBe(200)
      const token = loginResponse.data.token

      // Step 3: Create Event
      const event = {
        title: `Journey Event ${timestamp}`,
        description: 'Full journey test event',
        startDate: new Date(Date.now() + 86400000).toISOString(),
        endDate: new Date(Date.now() + 172800000).toISOString(),
        ticketPrice: 149.99,
        personLimit: 200,
        location: 'Journey Venue'
      }

      const createResponse = await axios.post(
        `${API_BASE}/api/events`,
        event,
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      )
      expect(createResponse.status).toBe(200)
      const eventId = createResponse.data.id

      // Step 4: Fetch events and verify our event is there
      const eventsResponse = await axios.get(`${API_BASE}/api/events`)
      expect(eventsResponse.status).toBe(200)
      expect(eventsResponse.data).toHaveProperty('content')
      const foundEvent = eventsResponse.data.content.find((e: any) => e.id === eventId)
      expect(foundEvent).toBeTruthy()
      expect(foundEvent.title).toBe(event.title)

      // Step 5: Fetch single event
      const singleEventResponse = await axios.get(`${API_BASE}/api/events/${eventId}`)
      expect(singleEventResponse.status).toBe(200)
      expect(singleEventResponse.data.id).toBe(eventId)
      expect(singleEventResponse.data.title).toBe(event.title)

      console.log('✅ Full user journey completed successfully!')
    })
  })
})
