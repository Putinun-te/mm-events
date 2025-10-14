describe('Bookings API E2E Tests', () => {
  const apiUrl = Cypress.env('apiUrl')
  const timestamp = Date.now()
  let authToken
  let createdBookingId

  before(() => {
    // Register and login to get authentication token
    cy.request({
      method: 'POST',
      url: `${apiUrl}/auth/register`,
      body: {
        username: `bookinguser${timestamp}`,
        email: `bookinguser${timestamp}@example.com`,
        password: 'BookingUser123!',
        name: 'Booking Test User'
      }
    }).then((response) => {
      authToken = response.body.token
      Cypress.env('authToken', authToken)
    })
  })

  describe('POST /api/bookings', () => {
    it('should create a new booking successfully', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 15)

      cy.request({
        method: 'POST',
        url: `${apiUrl}/bookings`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        body: {
          eventId: 1,
          eventTitle: `Test Event for Booking ${timestamp}`,
          eventLocation: 'Booking Test Location',
          eventStartDate: futureDate.toISOString(),
          quantity: 2,
          ticketPrice: 50.00
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.have.property('id')
        expect(response.body).to.have.property('eventTitle')
        expect(response.body).to.have.property('quantity', 2)
        expect(response.body).to.have.property('status', 'CONFIRMED')
        expect(response.body).to.have.property('totalPrice')
        createdBookingId = response.body.id
      })
    })

    it('should create booking with multiple tickets', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 20)

      cy.request({
        method: 'POST',
        url: `${apiUrl}/bookings`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        body: {
          eventId: 2,
          eventTitle: 'Multi-ticket Event',
          eventLocation: 'Multi Location',
          eventStartDate: futureDate.toISOString(),
          quantity: 10,
          ticketPrice: 25.00
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body.quantity).to.eq(10)
        expect(response.body.totalPrice).to.eq(250.00)
      })
    })

    it('should fail to create booking without authentication', () => {
      cy.request({
        method: 'POST',
        url: `${apiUrl}/bookings`,
        body: {
          eventId: 1,
          eventTitle: 'Unauthorized Booking',
          quantity: 1,
          ticketPrice: 50.00
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })
  })

  describe('GET /api/bookings/me', () => {
    before(() => {
      // Create multiple bookings for testing
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 25)

      for (let i = 1; i <= 3; i++) {
        cy.request({
          method: 'POST',
          url: `${apiUrl}/bookings`,
          headers: {
            Authorization: `Bearer ${authToken}`
          },
          body: {
            eventId: i + 10,
            eventTitle: `My Booking Event ${i}`,
            eventLocation: `Location ${i}`,
            eventStartDate: new Date(futureDate.getTime() + i * 86400000).toISOString(),
            quantity: i,
            ticketPrice: i * 30.00
          }
        })
      }
    })

    it('should return all user bookings', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/bookings/me`,
        headers: {
          Authorization: `Bearer ${authToken}`
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.be.an('array')
        expect(response.body.length).to.be.greaterThan(0)
        response.body.forEach(booking => {
          expect(booking).to.have.property('id')
          expect(booking).to.have.property('eventTitle')
          expect(booking).to.have.property('quantity')
          expect(booking).to.have.property('status')
        })
      })
    })

    it('should require authentication', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/bookings/me`,
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })

    it('should return bookings in descending order by booking date', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/bookings/me`,
        headers: {
          Authorization: `Bearer ${authToken}`
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        const bookings = response.body
        if (bookings.length > 1) {
          for (let i = 0; i < bookings.length - 1; i++) {
            const currentDate = new Date(bookings[i].bookingDate)
            const nextDate = new Date(bookings[i + 1].bookingDate)
            expect(currentDate.getTime()).to.be.at.least(nextDate.getTime())
          }
        }
      })
    })
  })

  describe('GET /api/bookings/:id', () => {
    it('should get specific booking by ID', () => {
      if (createdBookingId) {
        cy.request({
          method: 'GET',
          url: `${apiUrl}/bookings/${createdBookingId}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        }).then((response) => {
          expect(response.status).to.eq(200)
          expect(response.body).to.have.property('id', createdBookingId)
          expect(response.body).to.have.property('eventTitle')
          expect(response.body).to.have.property('quantity')
          expect(response.body).to.have.property('status')
        })
      }
    })

    it('should return error for non-existent booking', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/bookings/999999`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([404, 500])
      })
    })

    it('should require authentication', () => {
      if (createdBookingId) {
        cy.request({
          method: 'GET',
          url: `${apiUrl}/bookings/${createdBookingId}`,
          failOnStatusCode: false
        }).then((response) => {
          expect(response.status).to.be.oneOf([401, 403])
        })
      }
    })
  })

  describe('DELETE /api/bookings/:id', () => {
    let bookingToCancel

    before(() => {
      // Create a booking to cancel
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 30)

      cy.request({
        method: 'POST',
        url: `${apiUrl}/bookings`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        body: {
          eventId: 100,
          eventTitle: 'Cancellable Booking Event',
          eventLocation: 'Cancel Test Location',
          eventStartDate: futureDate.toISOString(),
          quantity: 5,
          ticketPrice: 40.00
        }
      }).then((response) => {
        bookingToCancel = response.body.id
      })
    })

    it('should cancel a booking successfully', () => {
      if (bookingToCancel) {
        cy.request({
          method: 'DELETE',
          url: `${apiUrl}/bookings/${bookingToCancel}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        }).then((response) => {
          expect(response.status).to.eq(204)
        })
      }
    })

    it('should verify booking status changed to CANCELLED', () => {
      if (bookingToCancel) {
        cy.request({
          method: 'GET',
          url: `${apiUrl}/bookings/${bookingToCancel}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        }).then((response) => {
          expect(response.status).to.eq(200)
          expect(response.body.status).to.eq('CANCELLED')
        })
      }
    })

    it('should return error when cancelling non-existent booking', () => {
      cy.request({
        method: 'DELETE',
        url: `${apiUrl}/bookings/999999`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([404, 500])
      })
    })

    it('should require authentication to cancel booking', () => {
      if (createdBookingId) {
        cy.request({
          method: 'DELETE',
          url: `${apiUrl}/bookings/${createdBookingId}`,
          failOnStatusCode: false
        }).then((response) => {
          expect(response.status).to.be.oneOf([401, 403])
        })
      }
    })
  })

  describe('Booking Flow Integration', () => {
    it('should complete full booking lifecycle', () => {
      const futureDate = new Date()
      futureDate.setDate(futureDate.getDate() + 45)
      let bookingId

      // Step 1: Create booking
      cy.request({
        method: 'POST',
        url: `${apiUrl}/bookings`,
        headers: {
          Authorization: `Bearer ${authToken}`
        },
        body: {
          eventId: 200,
          eventTitle: 'Full Lifecycle Event',
          eventLocation: 'Lifecycle Location',
          eventStartDate: futureDate.toISOString(),
          quantity: 3,
          ticketPrice: 60.00
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        bookingId = response.body.id
        expect(response.body.status).to.eq('CONFIRMED')

        // Step 2: Retrieve booking
        return cy.request({
          method: 'GET',
          url: `${apiUrl}/bookings/${bookingId}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        })
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body.id).to.eq(bookingId)
        expect(response.body.status).to.eq('CONFIRMED')

        // Step 3: Cancel booking
        return cy.request({
          method: 'DELETE',
          url: `${apiUrl}/bookings/${bookingId}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        })
      }).then((response) => {
        expect(response.status).to.eq(204)

        // Step 4: Verify cancellation
        return cy.request({
          method: 'GET',
          url: `${apiUrl}/bookings/${bookingId}`,
          headers: {
            Authorization: `Bearer ${authToken}`
          }
        })
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body.status).to.eq('CANCELLED')
      })
    })
  })
})
