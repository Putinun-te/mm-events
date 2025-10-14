// Custom Cypress commands for backend API testing

/**
 * Login command to authenticate and get JWT token
 */
Cypress.Commands.add('login', (username = 'testuser', password = 'password123') => {
  return cy.request({
    method: 'POST',
    url: `${Cypress.env('apiUrl')}/auth/login`,
    body: {
      username,
      password
    }
  }).then((response) => {
    expect(response.status).to.eq(200)
    expect(response.body).to.have.property('token')
    Cypress.env('authToken', response.body.token)
    return response.body.token
  })
})

/**
 * Register new user command
 */
Cypress.Commands.add('register', (username, email, password, name) => {
  return cy.request({
    method: 'POST',
    url: `${Cypress.env('apiUrl')}/auth/register`,
    body: {
      username,
      email,
      password,
      name
    }
  })
})

/**
 * Make authenticated request
 */
Cypress.Commands.add('authenticatedRequest', (method, url, body = null) => {
  const token = Cypress.env('authToken')
  const options = {
    method,
    url: `${Cypress.env('apiUrl')}${url}`,
    headers: {
      Authorization: `Bearer ${token}`
    },
    failOnStatusCode: false
  }
  
  if (body) {
    options.body = body
  }
  
  return cy.request(options)
})

/**
 * Create event command
 */
Cypress.Commands.add('createEvent', (eventData) => {
  return cy.authenticatedRequest('POST', '/events', eventData)
})

/**
 * Create booking command
 */
Cypress.Commands.add('createBooking', (bookingData) => {
  return cy.authenticatedRequest('POST', '/bookings', bookingData)
})

/**
 * Clean up test data (called in beforeEach)
 */
Cypress.Commands.add('cleanupTestData', () => {
  // Note: This assumes you have cleanup endpoints or can use test database
  cy.log('Test data cleanup - implement based on your backend capabilities')
})
