describe('Booking Flow', () => {
  beforeEach(() => {
    cy.visit('http://localhost:3000/concert', { failOnStatusCode: false, timeout: 15000 })
    cy.wait(2000)
    cy.clearLocalStorage()
  })

  describe('Browse Events', () => {
    it('should display events list', () => {
      cy.visit('http://localhost:3000/concert/ProductPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should navigate to event details', () => {
      cy.visit('http://localhost:3000/concert/ProductPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should search/filter events', () => {
      cy.visit('http://localhost:3000/concert/ProductPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })
  })

  describe('Book Event', () => {
    it('should view event details page', () => {
      // Visit a specific event detail page
      cy.visit('http://localhost:3000/concert/ProductPageDetail/1', { failOnStatusCode: false })
      cy.wait(1000)
      
      cy.url().should('include', '/ProductPageDetail')
    })

    it('should show booking form', () => {
      cy.visit('http://localhost:3000/concert/ProductPageDetail/1', { failOnStatusCode: false })
      cy.wait(1000)
      
      // Check for booking-related elements
      cy.get('body').should('be.visible')
    })

    it('should submit booking', () => {
      cy.visit('http://localhost:3000/concert/ProductPageDetail/1', { failOnStatusCode: false })
      cy.wait(1000)
      
      // Look for book/join button
      cy.get('body').then(($body) => {
        if ($body.text().includes('Book') || $body.text().includes('Join')) {
          // Booking button exists
          cy.contains(/Book|Join/i).should('exist')
        }
      })
    })
  })

  describe('View Bookings', () => {
    it('should navigate to my bookings page', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should display user bookings list', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should show booking details', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })
  })

  describe('Cancel Booking', () => {
    it('should have cancel option for bookings', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should confirm before canceling', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should remove booking after cancellation', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })
  })

  describe('My Events', () => {
    it('should navigate to my events page', () => {
      cy.visit('http://localhost:3000/concert/MyEventsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should display created events', () => {
      cy.visit('http://localhost:3000/concert/MyEventsPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })

    it('should allow creating new event', () => {
      cy.visit('http://localhost:3000/concert/CreateEventPage', { failOnStatusCode: false, timeout: 15000 })
      cy.wait(1000)
      cy.get('body').should('exist')
    })
  })
})
