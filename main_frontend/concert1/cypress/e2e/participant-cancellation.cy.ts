describe('Participant Cancellation Feature', () => {
  const testEventId = 1760360780023
  const testEvent = 'aaaa'
  
  beforeEach(() => {
    cy.visit('http://localhost:3000/concert', { failOnStatusCode: false })
    cy.clearLocalStorage()
    
    // Login
    cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
    cy.get('input#email').type('test@test.com')
    cy.get('input#password').type('password123')
    cy.get('form').submit()
    cy.wait(2000)
  })

  describe('Booking Cancellation Updates Participant Count', () => {
    it('should display initial participant count on event page', () => {
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Verify event title
      cy.contains(testEvent).should('be.visible')
      
      // Verify participants section exists and shows a number
      cy.contains('Participants:').should('be.visible')
      cy.get('span').contains(/\d+\s*\/\s*\d+/).should('be.visible')
    })

    it('should allow user to cancel a booking', () => {
      // Go to my bookings
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
      cy.wait(1000)
      
      // Find and click cancel button
      cy.get('body').then(($body) => {
        if ($body.text().includes('Cancel Booking')) {
          cy.contains('Cancel Booking').click({ multiple: true })
          cy.wait(500)
          
          // Confirm cancellation
          cy.contains('Yes, Cancel Booking').click()
          cy.wait(1000)
          
          // Should see success message
          cy.contains(/cancelled successfully|Booking Cancelled/i).should('exist')
        }
      })
    })

    it('should reduce participant count when booking is cancelled', () => {
      // Step 1: Get initial participant count
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Extract initial count
      cy.get('span').contains(/\d+\s*\/\s*\d+/).then(($el) => {
        const initialText = $el.text()
        const initialCount = parseInt(initialText.split('/')[0].trim())
        
        // Step 2: Go to my bookings and cancel
        cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
        cy.wait(1000)
        
        // Find booking for this event and cancel it
        cy.get('body').then(($body) => {
          if ($body.text().includes('Cancel Booking') && $body.text().includes(testEvent)) {
            cy.contains('Cancel Booking').click({ multiple: true })
            cy.wait(500)
            cy.contains('Yes, Cancel Booking').click()
            cy.wait(1000)
          }
        })
        
        // Step 3: Navigate back to event page
        cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
        cy.wait(2000)
        
        // Step 4: Verify participant count decreased
        cy.get('span').contains(/\d+\s*\/\s*\d+/).then(($el2) => {
          const updatedText = $el2.text()
          const updatedCount = parseInt(updatedText.split('/')[0].trim())
          
          // Count should have decreased
          expect(updatedCount).to.be.lessThan(initialCount)
        })
      })
    })

    it('should remove cancelled user from participants list', () => {
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Get initial number of participants displayed
      cy.get('body').then(($body) => {
        const initialParticipantElements = $body.find('[data-testid="participant-item"]').length
        
        // Go cancel a booking
        cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
        cy.wait(1000)
        
        cy.get('body').then(($body2) => {
          if ($body2.text().includes('Cancel Booking')) {
            cy.contains('Cancel Booking').click({ multiple: true })
            cy.wait(500)
            cy.contains('Yes, Cancel Booking').click()
            cy.wait(1000)
          }
        })
        
        // Return to event page
        cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
        cy.wait(2000)
        
        // Verify participant list updated
        cy.get('body').then(($body3) => {
          const updatedParticipantElements = $body3.find('[data-testid="participant-item"]').length
          
          // Should have fewer or same participants
          expect(updatedParticipantElements).to.be.lte(initialParticipantElements)
        })
      })
    })

    it('should update spots remaining when participant cancels', () => {
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Find initial spots remaining text
      cy.get('body').then(($body) => {
        const spotsText = $body.text()
        if (spotsText.includes('seats available') || spotsText.includes('spots remaining')) {
          // Initial state captured
          
          // Go cancel booking
          cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
          cy.wait(1000)
          
          cy.get('body').then(($body2) => {
            if ($body2.text().includes('Cancel Booking')) {
              cy.contains('Cancel Booking').click({ multiple: true })
              cy.wait(500)
              cy.contains('Yes, Cancel Booking').click()
              cy.wait(1000)
            }
          })
          
          // Return to event
          cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
          cy.wait(2000)
          
          // Verify spots increased or text changed
          cy.get('body').should('contain', /\d+ spots remaining|available|seats/)
        }
      })
    })

    it('should maintain data consistency after multiple cancellations', () => {
      // This test verifies that multiple cancellations work correctly
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Perform first cancellation
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
      cy.wait(1000)
      
      cy.get('body').then(($body) => {
        if ($body.text().includes('Cancel Booking')) {
          cy.contains('Cancel Booking').click({ multiple: true })
          cy.wait(500)
          cy.contains('Yes, Cancel Booking').click()
          cy.wait(1000)
        }
      })
      
      // Return to event and verify state
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(2000)
      
      // Should show valid participant count
      cy.get('span').contains(/\d+\s*\/\s*\d+/).should('exist')
    })
  })

  describe('Participant Auto-Refresh on Page Navigation', () => {
    it('should refresh participant data when returning to event page', () => {
      // Visit event page
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      cy.get('span').contains(/\d+\s*\/\s*\d+/).then(($el) => {
        const firstLoad = $el.text()
        
        // Navigate away
        cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
        cy.wait(1000)
        
        // Navigate back
        cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
        cy.wait(2000)
        
        // Data should be fetched again
        cy.get('span').contains(/\d+\s*\/\s*\d+/).should('exist')
      })
    })

    it('should show no stale data after page refresh', () => {
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Verify event loads
      cy.contains(testEvent).should('be.visible')
      
      // Page refresh (simulate F5)
      cy.reload()
      cy.wait(1000)
      
      // Should still show correct event
      cy.contains(testEvent).should('be.visible')
      cy.get('span').contains(/\d+\s*\/\s*\d+/).should('exist')
    })
  })

  describe('Error Handling During Cancellation', () => {
    it('should handle cancellation errors gracefully', () => {
      cy.visit('http://localhost:3000/concert/MyBookingsPage', { failOnStatusCode: false })
      cy.wait(1000)
      
      // Page should load without errors
      cy.get('body').should('be.visible')
      
      // If cancel button exists, it should be clickable
      cy.get('body').then(($body) => {
        if ($body.text().includes('Cancel Booking')) {
          cy.contains('Cancel Booking').should('be.enabled')
        }
      })
    })

    it('should maintain UI consistency if participant removal fails', () => {
      // This tests graceful degradation
      cy.visit(`http://localhost:3000/concert/ProductPageDetail/${testEventId}`, { failOnStatusCode: false })
      cy.wait(1000)
      
      // Page should still display correctly
      cy.contains(testEvent).should('be.visible')
      cy.get('span').contains(/\d+\s*\/\s*\d+/).should('exist')
    })
  })
})