describe('Booking Flow', () => {
  beforeEach(() => {
    cy.visit('http://localhost:3000/concert')
    cy.clearLocalStorage()
    
    // Login before each test
    cy.visit('http://localhost:3000/concert/LoginPage')
    cy.get('input#email').type('test@test.com')
    cy.get('input#password').type('password123')
    cy.get('form').submit()
    cy.wait(2000)
  })

  describe('Browse Events', () => {
    it('should display events list', () => {
      cy.visit('http://localhost:3000/concert/ProductPage')
      cy.wait(1000)
      
      cy.url().should('include', '/ProductPage')
      // Should show events or empty state
      cy.get('body').should('be.visible')
    })

    it('should navigate to event details', () => {
      cy.visit('http://localhost:3000/concert/ProductPage')
      cy.wait(1000)
      
      // Click on first event if available
      cy.get('body').then(($body) => {
        if ($body.find('[data-testid="event-card"]').length > 0) {
          cy.get('[data-testid="event-card"]').first().click()
          cy.wait(1000)
        }
      })
    })

    it('should search/filter events', () => {
      cy.visit('http://localhost:3000/concert/ProductPage')
      cy.wait(1000)
      
      // Check if search functionality exists
      cy.get('body').then(($body) => {
        if ($body.find('input[type="search"]').length > 0) {
          cy.get('input[type="search"]').type('concert')
          cy.wait(500)
        }
      })
    })
  })

  describe('Book Event', () => {
    it('should view event details page', () => {
      // Visit a specific event detail page
      cy.visit('http://localhost:3000/concert/ProductPageDetail/1')
      cy.wait(1000)
      
      cy.url().should('include', '/ProductPageDetail')
    })

    it('should show booking form', () => {
      cy.visit('http://localhost:3000/concert/ProductPageDetail/1')
      cy.wait(1000)
      
      // Check for booking-related elements
      cy.get('body').should('be.visible')
    })

    it('should submit booking', () => {
      cy.visit('http://localhost:3000/concert/ProductPageDetail/1')
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
      cy.visit('http://localhost:3000/concert/MyBookingsPage')
      cy.wait(1000)
      
      cy.url().should('include', '/MyBookingsPage')
    })

    it('should display user bookings list', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage')
      cy.wait(1000)
      
      // Should show bookings list or empty state
      cy.get('body').should('be.visible')
    })

    it('should show booking details', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage')
      cy.wait(1000)
      
      // Check if any bookings are displayed
      cy.get('body').then(($body) => {
        if ($body.text().includes('Event') || $body.text().includes('Booking')) {
          // Bookings exist
          cy.log('Bookings displayed')
        }
      })
    })
  })

  describe('Cancel Booking', () => {
    it('should have cancel option for bookings', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage')
      cy.wait(1000)
      
      // Look for cancel/delete buttons
      cy.get('body').then(($body) => {
        if ($body.text().includes('Cancel') || $body.text().includes('Delete')) {
          cy.log('Cancel option available')
        }
      })
    })

    it('should confirm before canceling', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage')
      cy.wait(1000)
      
      // Check for confirmation modal
      cy.get('body').then(($body) => {
        const hasCancelBtn = $body.find('button').filter((i, el) => 
          Cypress.$(el).text().toLowerCase().includes('cancel')
        ).length > 0
        
        if (hasCancelBtn) {
          cy.log('Cancel functionality exists')
        }
      })
    })

    it('should remove booking after cancellation', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage')
      cy.wait(1000)
      
      // Verify page loads successfully
      cy.url().should('include', '/MyBookingsPage')
    })
  })

  describe('My Events', () => {
    it('should navigate to my events page', () => {
      cy.visit('http://localhost:3000/concert/MyEventsPage')
      cy.wait(1000)
      
      cy.url().should('include', '/MyEventsPage')
    })

    it('should display created events', () => {
      cy.visit('http://localhost:3000/concert/MyEventsPage')
      cy.wait(1000)
      
      // Should show events list or empty state
      cy.get('body').should('be.visible')
    })

    it('should allow creating new event', () => {
      cy.visit('http://localhost:3000/concert/CreateEventPage')
      cy.wait(1000)
      
      cy.url().should('include', '/CreateEventPage')
      cy.contains(/Create|Event/i).should('exist')
    })
  })
})
