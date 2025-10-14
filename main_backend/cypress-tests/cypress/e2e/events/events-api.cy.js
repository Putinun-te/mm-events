describe('Events API E2E Tests', () => {
  const apiUrl = Cypress.env('apiUrl')
  const timestamp = Date.now()
  let authToken
  let createdEventId

  before(() => {
    // Register and login to get authentication token
    cy.request({
      method: 'POST',
      url: `${apiUrl}/auth/register`,
      body: {
        username: `eventuser${timestamp}`,
        email: `eventuser${timestamp}@example.com`,
        password: 'EventUser123!',
        name: 'Event Test User'
      }
    }).then((response) => {
      authToken = response.body.token
      Cypress.env('authToken', authToken)
    })
  })

  describe('POST /api/events', () => {
    it('should create a new event successfully', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)
      const endDate = new Date(futureDate)
      endDate.setDate(endDate.getDate() + 1)

      cy.request({
        method: 'POST',
        url: `${apiUrl}/events`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        body: {
          title: `Test Event ${timestamp}`,
          description: 'This is a test event',
          category: 'Music',
          location: 'Test Venue',
          address: '123 Test Street',
          city: 'Test City',
          country: 'Test Country',
          personLimit: 100,
          phone: '1234567890',
          startDate: futureDate.toISOString(),
          endDate: endDate.toISOString(),
          ticketPrice: 50.00
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.have.property('id')
        expect(response.body).to.have.property('title', `Test Event ${timestamp}`)
        expect(response.body).to.have.property('category', 'Music')
        expect(response.body).to.have.property('ownedByCurrentUser', true)
        createdEventId = response.body.id
      })
    })

    it('should fail to create event without authentication', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      cy.request({
        method: 'POST',
        url: `${apiUrl}/events`,
        body: {
          title: 'Unauthorized Event',
          description: 'This should fail',
          category: 'Sports',
          location: 'Test Location',
          startDate: futureDate.toISOString(),
          endDate: new Date(futureDate.getTime() + 86400000).toISOString(),
          ticketPrice: 25.00
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })

    it('should fail to create event with invalid date range', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)
      const pastDate = new Date()
      pastDate.setDate(pastDate.getDate() + 20)

      cy.request({
        method: 'POST',
        url: `${apiUrl}/events`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        body: {
          title: 'Invalid Date Event',
          description: 'End date before start date',
          category: 'Conference',
          location: 'Test Location',
          startDate: futureDate.toISOString(),
          endDate: pastDate.toISOString(),
          ticketPrice: 100.00
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([400, 422, 500])
      })
    })
  })

  describe('GET /api/events', () => {
    before(() => {
      // Create multiple events for list testing
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 40)
      
      for (let i = 1; i <= 3; i++) {
        cy.request({
          method: 'POST',
          url: `${apiUrl}/events`,
          headers: {
            Authorization: `Bearer ${authToken}`
          },
          body: {
            title: `List Event ${i} ${timestamp}`,
            description: `Description ${i}`,
            category: 'Festival',
            location: `Location ${i}`,
            startDate: new Date(futureDate.getTime() + i * 86400000).toISOString(),
            endDate: new Date(futureDate.getTime() + (i + 1) * 86400000).toISOString(),
            ticketPrice: i * 25.00
          }
        })
      }
    })

    it('should list all upcoming events', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/events`
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.have.property('content')
        expect(response.body.content).to.be.an('array')
        expect(response.body).to.have.property('totalElements')
        expect(response.body.totalElements).to.be.greaterThan(0)
      })
    })

    it('should support pagination', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/events?page=0&size=2`
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body.content).to.have.length.at.most(2)
        expect(response.body).to.have.property('totalPages')
      })
    })

    it('should work without authentication', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/events`
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body.content).to.be.an('array')
      })
    })
  })

  describe('GET /api/events/me', () => {
    it('should return organizer events', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/events/me`,
        headers: {
          Authorization: `Bearer ${authToken}`
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.be.an('array')
        expect(response.body.length).to.be.greaterThan(0)
        response.body.forEach(event => {
          expect(event).to.have.property('ownedByCurrentUser', true)
        })
      })
    })

    it('should require authentication', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/events/me`,
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })
  })

  describe('GET /api/events/:id', () => {
    it('should get specific event by ID', () => {
      if (createdEventId) {
        cy.request({
          method: 'GET',
          url: `${apiUrl}/events/${createdEventId}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        }).then((response) => {
          expect(response.status).to.eq(200)
          expect(response.body).to.have.property('id', createdEventId)
          expect(response.body).to.have.property('title')
          expect(response.body).to.have.property('category')
        })
      }
    })

    it('should return error for non-existent event', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/events/999999`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([404, 500])
      })
    })

    it('should work without authentication for public events', () => {
      if (createdEventId) {
        cy.request({
          method: 'GET',
          url: `${apiUrl}/events/${createdEventId}`
        }).then((response) => {
          expect(response.status).to.eq(200)
          expect(response.body).to.have.property('id', createdEventId)
        })
      }
    })
  })
})
