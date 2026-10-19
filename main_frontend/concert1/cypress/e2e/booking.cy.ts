describe('Booking tickets', () => {
  it('books a ticket, shows it in My Bookings and cancels it', () => {
    cy.apiUser('organizer').then(organizer => {
      const title = `Cypress Booking ${Date.now()}`
      cy.apiEvent(organizer, { title, ticketPrice: 30 }).then(eventId => {
        cy.apiUser('fan').then(fan => {
          cy.visitAs(fan, `/product-page-detail/${eventId}`)

          cy.contains('button', 'Book 1 Ticket').click()
          cy.contains('Booking Confirmed').should('be.visible')

          cy.location('pathname', { timeout: 15000 }).should('include', '/MyBookingsPage')
          cy.contains('.booking-card', title).within(() => {
            cy.contains('CONFIRMED').should('be.visible')
            cy.contains('button', 'Cancel Booking').click()
          })
          cy.contains('button', 'Yes, Cancel Booking').click()

          cy.contains('.booking-card', title).contains('CANCELLED').should('be.visible')
        })
      })
    })
  })

  it('cancels a booking after the access token expired without logging out', () => {
    cy.apiUser('organizer').then(organizer => {
      const title = `Cypress Expired Cancel ${Date.now()}`
      cy.apiEvent(organizer, { title }).then(eventId => {
        cy.apiUser('idle').then(fan => {
          cy.apiBook(fan, eventId, 1).its('status').should('eq', 200)
          cy.visitAs(fan, '/MyBookingsPage')
          cy.contains('.booking-card', title).contains('CONFIRMED').should('be.visible')

          // the user was idle for 15 minutes: the backend no longer accepts the access token
          cy.window().then(win => win.localStorage.setItem('jwt_token', 'expired.access.token'))
          cy.intercept('POST', '**/api/auth/refresh').as('refresh')
          cy.intercept('DELETE', '**/api/bookings/*').as('cancel')

          cy.contains('.booking-card', title).within(() => {
            cy.contains('button', 'Cancel Booking').click()
          })
          cy.contains('button', 'Yes, Cancel Booking').click()

          cy.wait('@cancel').its('response.statusCode').should('eq', 401)
          cy.wait('@refresh').its('response.statusCode').should('eq', 200)
          cy.wait('@cancel').its('response.statusCode').should('be.within', 200, 299)
          cy.contains('Booking Cancelled').should('be.visible')
          cy.contains('.booking-card', title).contains('CANCELLED').should('be.visible')
          cy.location('pathname').should('eq', '/MyBookingsPage')
        })
      })
    })
  })

  it('shows the server message when the last seats are taken first', () => {
    cy.apiUser('organizer').then(organizer => {
      cy.apiEvent(organizer, { personLimit: 2 }).then(eventId => {
        cy.apiUser('late').then(late => {
          cy.apiUser('early').then(early => {
            // The page still shows 2 free seats when it loads...
            cy.visitAs(late, `/product-page-detail/${eventId}`)
            cy.contains('button', 'Book 1 Ticket').should('be.visible')

            // ...then someone else books both of them.
            cy.apiBook(early, eventId, 2).its('status').should('eq', 200)

            cy.contains('button', 'Book 1 Ticket').click()
            cy.contains('Booking Failed').should('be.visible')
            cy.contains('This event is sold out').should('be.visible')
            cy.location('pathname').should('include', `/product-page-detail/${eventId}`)
          })
        })
      })
    })
  })
})
